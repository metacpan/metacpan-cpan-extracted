use 5.008;
use warnings;
use strict;

package Class::Scaffold::Introspect;
BEGIN {
  $Class::Scaffold::Introspect::VERSION = '1.102280';
}
# ABSTRACT: Find configuration files within the framework
use FindBin '$Bin';
use Cwd;
use File::Spec::Functions qw/curdir updir rootdir rel2abs/;
use Sys::Hostname;
use Exporter qw(import);
our %EXPORT_TAGS = (conf => [qw/find_conf_file/],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub find_file_upwards {
    my $wanted_file  = shift;
    my $previous_cwd = getcwd;
    my $result;    # left undef as we'll return undef if we didn't find it
    while (rel2abs(curdir()) ne rootdir()) {
        if (-f $wanted_file) {
            $result = rel2abs(curdir());
            last;
        }
        chdir(updir());
    }
    chdir($previous_cwd);
    $result;
}

sub find_conf_file {
    my $file = 'SMOKEconf.yaml';

    # the distribution root is where Build.PL is; start the search from where
    # the bin file was (presumably within the distro). This way we can say any
    # of:
    #
    # perl t/sometest.t
    # cd t; perl sometest.t
    # perl /abs/path/to/distro/t/sometest.t
    chdir($Bin) or die "can't chdir to [$Bin]: $!\n";
    my $distro_root = find_file_upwards('Makefile.PL')
        || find_file_upwards('dist.ini');
    unless (defined $distro_root && length $distro_root) {
        warn "can't find distro root from [$Bin]\n";
        warn "might not be able to find conf file using [$ENV{CF_CONF}]\n"
          if $ENV{CF_CONF} eq 'local';
        return;
    }
    my $etc = "$distro_root/etc";
    return "$etc/$file" if -e "$etc/$file";

    # warn "find_conf_file: not in [$etc/$file]";
    (my $hostname = hostname) =~ s/\W.*//;
    my $dir = "$etc/$hostname";
    return "$dir/$file" if -d $dir && -e "$dir/$file";

    # warn "find_conf_file: not in [$dir/$file]";
    undef;
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Introspect - Find configuration files within the framework

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 find_conf_file

FIXME

=head2 find_file_upwards

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

