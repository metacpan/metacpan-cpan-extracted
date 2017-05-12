package App::Mver;

use strict;
use version;
use warnings;

use ExtUtils::MakeMaker;

our $VERSION = '0.09';

my $module_corelist   = eval 'require Module::CoreList; 1';
my $lwp_useragent     = eval 'require LWP::Simple; 1';
my $json_any          = eval 'use JSON::Any; 1';
my $changes_parser    = eval 'require CPAN::Changes; 1';
my $can_do_requests   = $lwp_useragent && $json_any;
my $can_parse_changes = $can_do_requests && $changes_parser;

my $api_host         = 'http://api.metacpan.org';
my $module_search    = "$api_host/module/%s";
my $changelog_search = "$api_host/v0/file/_search?q=release:%s-%s AND (name:Changes OR name:ChangeLog OR name:CHANGES OR name:CHANGELOG OR name:Changelog)&fields=path";
my $source_search    = "$api_host/source/%s/%s/%s";

sub run {
    my($modules, $opts) = @_;

    $can_do_requests = 0 if $opts->{'no-internet'};
    $can_parse_changes = 0 unless $opts->{changes};

    mver($_) for @$modules;
}

sub mver {
    my $arg = shift;
    $arg =~ s{-}{::}g;

    print "$arg: ";
    if(lc $arg eq 'perl') {
        require Config;
        print $Config::Config{version};
    }
    else {
        my $file = MM->_installed_file_for_module($arg);
        if(defined $file) {
            my $version = eval { version->parse(MM->parse_version($file)) };
            if($version) {
                print $version;

                if($module_corelist and is_core($arg)) {
                    print ' (core module)';
                }
            }
            else {
                print 'installed, but $VERSION is not defined';
            }

            if($can_do_requests and $version) {
                my($latest, $author) = get_latest_version_and_author($arg);
                if($latest and $latest <= $version) {
                    print ' (latest)';
                }
                else {
                    print " (latest: $latest)";

                    if($can_parse_changes and $latest and $author) {
                        my $changes = get_changes_between($arg, $author, $version, $latest);
                        if($changes) {
                            print "$/Changes:$/$changes";
                        }
                    }
                }
            }
        }
        else {
            print 'not installed';
        }
    }
    print $/;
}

sub is_core {
    my $arg = shift;

    my($found_in_core) = Module::CoreList->find_modules(qr/^\Q$arg\E$/, $]);

    !!$found_in_core;
}

sub get_latest_version_and_author {
    my $arg = shift;

    my $json     = LWP::Simple::get(sprintf $module_search, $arg) or return;
    my $response = eval { JSON::Any->from_json($json) } or return;

    if($response->{status} eq 'latest') {
        my $version = version->parse($response->{version}) or return ();
        return ($version, $response->{author});
    }

    return ();
}

sub get_changes_between {
    my($arg, $author, $ver_start, $ver_stop) = @_;

    $arg =~ s/::/-/g;

    my $json      = LWP::Simple::get(sprintf $changelog_search, $arg, $ver_stop) or return;
    my $response  = eval { JSON::Any->from_json($json) } or return;
    my $first_hit = $response->{hits}{hits}[0]{fields} or return;

    my $raw = LWP::Simple::get(
        sprintf $source_search, $author,
                                "$arg-$ver_stop",
                                $first_hit->{path},
    ) or return;

    my $changes;
    if($raw) {
        my $parser = CPAN::Changes->load_string($raw);
        for my $release ($parser->releases) {
            my $curr = eval { version->parse($release->version) } or next;
            if($curr > $ver_start and $curr <= $ver_stop) {
                $changes .= $release->serialize;
            }
        }
    }

    $changes;
}

1;

__END__

=head1 NAME

App::Mver - just print modules' C<$VERSION> (and some other stuff)

=head1 DESCRIPTION

For those, who are sick of

    perl -MLong::Module::Name -le'print Long::Module::Name->VERSION'

The main purpose of this simple stupid tool is to save you some typing.

It will report you the following things (some of them require command line arguments):

=over 4

=item your installed version of the given module(s)

=item whether or not your current version is the last one available on CPAN

=item whether or not the module is included in Perl distribution

=item changes between installed and latest version

=back

=head1 SEE ALSO

L<mver>

=head1 AUTHOR

Alexey Surikov E<lt>ksuri@cpan.orgE<gt>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
