# App::hopen::Phase::Check - checking-phase operations
package App::hopen::Phase::Check;
use Data::Hopen;
use Data::Hopen::Base;
use parent 'Exporter';

our $VERSION = '0.000010';

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw();
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

# Docs {{{1

=head1 NAME

Data::Hopen::Phase::Check - Check the build system

=head1 SYNOPSIS

Check runs first.  Check reads a foundations file and outputs a capability
file and an options file.  The user can then edit the options file to
customize the build.

=cut

# }}}1

=head1 FUNCTIONS

=cut

1;
__END__
# vi: set fdm=marker: #
