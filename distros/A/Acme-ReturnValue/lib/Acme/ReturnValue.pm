#!/usr/bin/perl
package Acme::ReturnValue;

use 5.010;
use strict;
use warnings;
our $VERSION = '1.001';

# ABSTRACT: report interesting return values

use PPI;
use File::Find;
use Parse::CPAN::Packages;
use Path::Class qw();
use File::Temp qw(tempdir);
use File::Path;
use File::Copy;
use Archive::Any;
use Data::Dumper;
use JSON;
use Encode;
use Moose;
with qw(MooseX::Getopt);
use MooseX::Types::Path::Class;

has 'interesting' => (is=>'rw',isa=>'ArrayRef',default=>sub {[]});
has 'bad' => (is=>'rw',isa=>'ArrayRef',default=>sub {[]});
has 'failed' => (is=>'rw',isa=>'ArrayRef',default=>sub {[]});

has 'quiet' => (is=>'ro',isa=>'Bool',default=>0);
has 'inc' => (is=>'ro',isa=>'Bool',default=>0);
has 'dir' => (is=>'ro',isa=>'Path::Class::Dir',coerce=>1);
has 'file' => (is=>'ro',isa=>'Path::Class::File',coerce=>1);
has 'cpan' => (is=>'ro',isa=>'Path::Class::Dir',coerce=>1);
has 'dump_to' => (is=>'ro',isa=>'Path::Class::Dir',coerce=>1,default=>'returnvalues');

has 'json_encoder' => (is=>'ro',lazy_build=>1);
sub _build_json_encoder {
    return JSON->new->pretty;
}



sub run {
    my $self = shift;

    if ($self->inc) {
        $self->in_INC;
    }
    elsif ($self->dir) {
        $self->in_dir($self->dir);
    }
    elsif ($self->file) {
        $self->in_file($self->file);
    }
    elsif ($self->cpan) {
        $self->in_CPAN($self->cpan,$self->dump_to);
        exit;
    }
    else {
        $self->in_dir('.');
    }

    my $interesting=$self->interesting;
    if (@$interesting > 0) {
        foreach my $cool (@$interesting) {
            say $cool->{package} .': '.$cool->{value};
        }
    }
    else {
        say "boring!";
    }
}


sub waste_some_cycles {
    my ($self, $filename) = @_;

    my $doc = PPI::Document->new($filename);

    eval {  # I don't care if that fails...
        $doc->prune('PPI::Token::Comment');
        $doc->prune('PPI::Token::Pod');
    };

    my @packages=$doc->find('PPI::Statement::Package');
    my $this_package;

    foreach my $node ($packages[0][0]->children) {
        if ($node->isa('PPI::Token::Word')) {
            $this_package = $node->content;
        }
    }

    my @significant = grep { _is_code($_) } $doc->schildren();
    my $match = $significant[-1];
    my $rv=$match->content;
    $rv=~s/\s*;$//;
    $rv=~s/^return //gi;

    return if $rv eq 1;
    return if $rv eq '__PACKAGE__';
    return if $rv =~ /^__PACKAGE__->meta->make_immutable/;

    $rv = decode_utf8($rv);

    my $data = {
        'file'    => $filename,
        'package' => $this_package,
        'PPI'     => ref $match,
    };

    my @bad = map { 'PPI::Statement::'.$_} qw(Sub Variable Compound Package Scheduled Include Sub);

    if (ref($match) ~~ @bad) {
        $data->{'bad'}=$rv;
        push(@{$self->bad},$data);
    }
    elsif ($rv =~ /^('|"|\d|qw|qq|q|!|~)/) {
        $data->{'value'}=$rv;
        push(@{$self->interesting},$data);
    }
    else {
        $data->{'bad'}=$rv;
        $data->{'PPI'}.=" (but very likely crap)";
        push(@{$self->bad},$data);
    }
}


sub _is_code {
    my $elem = shift;
    return ! (    $elem->isa('PPI::Statement::End')
               || $elem->isa('PPI::Statement::Data'));
}


sub in_CPAN {
    my ($self,$cpan,$out)=@_;

    my $p=Parse::CPAN::Packages->new($cpan->file(qw(modules 02packages.details.txt.gz))->stringify);

    if (!-d $out) {
        $out->mkpath || die "cannot make dir $out";
    }

    # get all old data files so we can later delete non-current
    my %old_files;
    while (my $file = $out->next) {
        next unless $file =~ /\.json/;
        $old_files{$file->basename}=1;
    }

    # analyse cpan
    foreach my $dist (sort {$a->dist cmp $b->dist} $p->latest_distributions) {
        delete $old_files{$dist->distvname.'.json'};
        next if (-e $out->file($dist->distvname.'.json'));

        my $data;
        my $distfile = $cpan->file('authors','id',$dist->prefix);
        $data->{file}=$distfile;
        my $dir;
        eval {
            $dir = tempdir('/var/tmp/arv_XXXXXX');
            my $archive=Archive::Any->new($distfile->stringify) || die $!;
            $archive->extract($dir);

            $self->in_dir($dir,$dist->distvname);
        };
        if ($@) {
            say $@;
        }
        rmtree($dir);
    }

    # remove old data files
    foreach my $del (keys %old_files) {
        unlink($out->file($del)) || die $!;
    }

}


sub in_INC {
    my $self=shift;
    foreach my $dir (@INC) {
        $self->in_dir($dir,"INC_$dir");
    }
}


sub in_dir {
    my ($self,$dir,$dumpname)=@_;
    $dumpname ||= $dir;
    $dumpname=~s/\//_/g;

    say $dumpname unless $self->quiet;

    $self->interesting([]);
    $self->bad([]);
    my @pms;
    find(sub {
        return unless /\.pm\z/;
        return if $File::Find::name=~/\/x?t\//;
        return if $File::Find::name=~/\/inc\//;
        push(@pms,$File::Find::name);
    },$dir);

    foreach my $pm (@pms) {
        $self->in_file($pm);
    }

    my $dump=Path::Class::Dir->new($self->dump_to)->file($dumpname.".json");
    if ($self->interesting && @{$self->interesting}) {
        $dump->spew(iomode => '>:encoding(UTF-8)', $self->json_encoder->encode($self->interesting));
    }
    elsif ($self->bad && @{$self->bad}) {
        $dump->spew(iomode => '>:encoding(UTF-8)', $self->json_encoder->encode($self->bad));
    }
    else {
        $dump->spew('{"is_boring":"1"}');
    }
}


sub in_file {
    my ($self,$file)=@_;

    eval { $self->waste_some_cycles($file) };
    if ($@) {
        push (@{$self->failed},{file=>$file,error=>$@});
    }
}

"let's return a strange value";

__END__

=pod

=head1 NAME

Acme::ReturnValue - report interesting return values

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Acme::ReturnValue;
    my $rvs = Acme::ReturnValue->new;
    $rvs->in_INC;
    foreach (@{$rvs->interesting}) {
        say $_->{package} . ' returns ' . $_->{value};
    }

=head1 DESCRIPTION

C<Acme::ReturnValue> will list 'interesting' return values of modules.
'Interesting' means something other than '1'.

See L<http://returnvalues.useperl.at|http://returnvalues.useperl.at> for the results of running Acme::ReturnValue on the whole CPAN.

=head2 METHODS

=head3 run

run from the commandline (via F<acme_returnvalue.pl>

=head3 waste_some_cycles

    my $data = $arv->waste_some_cycles( '/some/module.pm' );

C<waste_some_cycles> parses the passed in file using PPI. It tries to
get the last statement and extract it's value.

C<waste_some_cycles> returns a hash with following keys

=over

=item * file

The file

=item * package

The package defintion (the first one encountered in the file

=item * value

The return value of that file

=back

C<waste_some_cycles> will also put this data structure into
L<interesting> or L<boring>.

You might want to pack calls to C<waste_some_cycles> into an C<eval>
because PPI dies on parse errors.

=head4 _is_code

Stolen directly from Perl::Critic::Policy::Modules::RequireEndWithOne
as suggested by Chris Dolan.

Thanks!

=head3 in_CPAN

Analyse CPAN. Needs a local CPAN mirror

=head3 in_INC

    $arv->in_INC;

Collect return values from all F<*.pm> files in C<< @INC >>.

=head3 in_dir

    $arv->in_dir( $some_dir );

Collect return values from all F<*.pm> files in C<< $dir >>.

=head3 in_file

    $arv->in_file( $some_file );

Collect return value from the passed in file.

If L<waste_some_cycles> failed, puts information on the failing file into L<failed>.

=head3 interesting

Returns an ARRAYREF containing 'interesting' modules.

=head3 boring

Returns an ARRAYREF containing 'boring' modules.

=head3 failed

Returns an ARRAYREF containing unparsable modules.

=head1 BUGS

Probably many, because I'm not sure I master PPI yet.

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
