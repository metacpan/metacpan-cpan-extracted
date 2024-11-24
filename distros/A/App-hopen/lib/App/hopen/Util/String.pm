# App::hopen::Util::String - string utilities for hopen
package App::hopen::Util::String;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'Exporter';
use vars::i '@EXPORT_OK' => qw(eval_here line_mark_string);
use vars::i '%EXPORT_TAGS' => (all => [@EXPORT_OK]);

# Docs {{{1

=head1 NAME

App::hopen::Util::String - string utilities for hopen

=head1 SYNOPSIS

A collection of miscellaneous string utilities.

=head1 FUNCTIONS

=cut

# }}}1

=head2 line_mark_string

Add a C<#line> directive to a string.  Usage:

    my $str = line_mark_string <<EOT ;
    $contents
    EOT

or

    my $str = line_mark_string __FILE__, __LINE__, <<EOT ;
    $contents
    EOT

In the first form, information from C<caller> will be used for the filename
and line number.

The C<#line> directive will point to the line after the C<line_mark_string>
invocation, i.e., the first line of <C$contents>.  Generally, C<$contents> will
be source code, although this is not required.

C<$contents> must be defined, but can be empty.

=cut

sub line_mark_string {
    my ($contents, $filename, $line);
    if(@_ == 1) {
        $contents = $_[0];
        (undef, $filename, $line) = caller;
    } elsif(@_ == 3) {
        ($filename, $line, $contents) = @_;
    } else {
        croak "Invalid invocation";
    }

    croak "Need text" unless defined $contents;
    die "Couldn't get location information" unless $filename && $line;

    $filename =~ s/"/-/g;
    ++$line;

    return <<EOT;
#line $line "$filename"
$contents
EOT
} #line_mark_string()

=head2 eval_here

C<eval> a string, but first, add a C<#line> directive.  Usage:

    eval_here <<EOT
    $code_to_run
    EOT

The C<#line> directive will point to the line after the C<eval_here> invocation,
i.e., the first line of <C$code_to_run>.

C<$code_to_run> must be defined, but can be empty.

The return value is the return value of the eval.  C<eval_here> does not
check C<$@>; that is the caller's responsibility.

=cut

sub eval_here {
    my $code_to_run = $_[0];
    croak "Need a code string to run" unless defined $code_to_run;

    my (undef, $filename, $line) = caller;
    die "Couldn't get caller's information" unless $filename && $line;

    $filename =~ s/"/-/g;
    ++$line;

    eval <<EOT;
#line $line "$filename"
$code_to_run
EOT
} #eval_here()

1;
__END__
# vi: set fdm=marker: #
