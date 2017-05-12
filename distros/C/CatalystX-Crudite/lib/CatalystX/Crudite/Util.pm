package CatalystX::Crudite::Util;
use strict;
use warnings;
use Exporter qw(import);
use Carp qw(croak);
use Data::Printer;
use Params::Validate qw(:all);
use File::Slurp qw(write_file);
use Template;
use File::ShareDir qw(dist_dir);
use File::Find;
use File::Path qw(mkpath);
our %EXPORT_TAGS = (
    util => [
        qw(
          merge_configs install_shared_files
          )
    ],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub get_ref {
    my $value = shift;
    return 'Undef' unless defined $value;
    ref $value || 'Scalar';
}

# merge nds2 into nds1 and return the result. nds1 gets clobbered.
sub merge_configs {
    my ($nds1, $nds2) = @_;
    return $nds2 unless defined $nds1;
    return $nds1 unless defined $nds2;
    my $ref1 = get_ref($nds1);
    my $ref2 = get_ref($nds2);
    if ($ref1 ne $ref2) {
        p $nds1;
        p $nds2;
        die "can't merge $ref1 and $ref2";
    }
    if ($ref1 eq 'HASH') {
        for my $key (keys $nds2) {
            if (exists $nds1->{$key}) {
                $nds1->{$key} = merge_configs($nds1->{$key}, $nds2->{$key});
            } else {
                $nds1->{$key} = $nds2->{$key};
            }
        }
        return $nds1;
    } elsif ($ref1 eq 'ARRAY') {
        return [ @$nds1, @$nds2 ];
    } elsif ($ref1 eq 'Scalar') {
        return defined $nds2 ? $nds2 : $nds1;
    } else {
        p $nds1;
        p $nds2;
        die "don't know what to do with $ref1";
    }
}

sub install_shared_files {
    my %args = validate(
        @_,
        {   share_path       => { type => SCALAR },
            dist_name        => { type => SCALAR },
            dist_dir         => { type => SCALAR },
            verbose          => { type => BOOLEAN, default => 0 },
            overwrite        => { type => BOOLEAN, default => 0 },
            dryrun           => { type => BOOLEAN, default => 0 },
            vars             => { type => HASHREF, default => {} },
            filename_replace => { type => HASHREF, default => {} },
        }
    );

    # It's not much fun to have a dry-run without output.
    $args{verbose}++ if $args{dryrun};

    # Log helper that closes over $args{verbose}
    my $log = sub {
        my $msg = "@_";
        return unless $args{verbose};
        1 while chomp $msg;
        print "$msg\n";
    };
    my $template_dir = dist_dir('CatalystX-Crudite') . "/$args{share_path}";

    # Need to use custom start and end tags because the starter files
    # contain templates themselves.
    my %vars = (
        dist_name   => $args{dist_name},
        dist_module => ($args{dist_name} =~ s/-/::/gr),
        dist_file   => "\L$args{dist_name}",
        %{ $args{vars} // {} },
    );
    my %filename_replace = (
        myapp => lc($args{dist_name} =~ s/-/_/gr),
        MyApp => ($args{dist_name} =~ s!(?:::|-)!/!gr),
        %{ $args{filename_replace} // {} },
    );
    my %result;

    # Don't copy the files directly, just record in %result what would
    # be done. This way we can check after the find() whether files
    # would be overwritten and, if necessary, abort. Then the files
    # are written in a separate loop at the end.
    find(
        sub {
            return unless -f;
            my $rel_name = $File::Find::name =~ s!^$template_dir/?!!r;
            $rel_name = '.gitignore' if $rel_name eq 'gitignore';
            while (my ($k, $v) = each %filename_replace) {
                $rel_name =~ s/$k/$v/g;
            }
            my $result_name = "$args{dist_dir}/$rel_name";

            # Some files are copied as-is.
            if (/\.png$/) {
                $result{$result_name} = { copy => $File::Find::name };
            } else {

                # Create a new template processor for each file;
                # with a shared template processor there seems to
                # be some sort of caching issue.
                my $template_processor = Template->new(
                    START_TAG => '<%',
                    END_TAG   => '%>',
                );
                my $content;
                $template_processor->process($_, \%vars, \$content)
                  || die $template_processor->error;
                $result{$result_name} = { write => $content };
            }
        },
        $template_dir
    );
    unless ($args{overwrite}) {
        if (my @exists = grep { -e } sort keys %result) {
            print "$_ exists, won't overwrite\n" for @exists;
            print "Aborting.\n";
            return;
        }
        if (my @exists = grep { -d } sort keys %result) {
            print "$_ exists as a directory\n" for @exists;
            print "Aborting.\n";
            return;
        }
    }
    for my $filename (sort keys %result) {
        (my $path = $filename) =~ s!^.*\K/.*!!;
        unless (-d $path) {
            $log->("mkpath $path");
            mkpath($path) unless $args{dryrun};
        }
        if (my $original = $result{$filename}{copy}) {
            $log->("copy -> $filename");
            unless ($args{dryrun}) {
                copy($original, $filename) or die "copy failed: $!";
            }
        } elsif (my $content = $result{$filename}{write}) {
            $log->("template -> $filename");
            write_file($filename, $content) unless $args{dryrun};
            chmod 0755, $filename if $filename =~ /\.(pl|sh)$/;
        }
    }
    $log->('Finished.');
}
1;
