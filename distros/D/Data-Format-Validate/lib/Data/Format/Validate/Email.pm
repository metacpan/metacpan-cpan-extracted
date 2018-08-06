package Data::Format::Validate::Email;
our $VERSION = q/0.3/;

use Carp;
use base q/Exporter/;

our @EXPORT_OK = qw/
    looks_like_any_email
    looks_like_common_email
/;

our %EXPORT_TAGS = (
    q/all/ => [qw/
        looks_like_any_email
        looks_like_common_email
    /]
);

sub looks_like_any_email {

    my $email = shift || croak q/Value most be provided/;
    $email =~ /^
        \S+ # Username (visible digits)
        @   # at
        \S+ # Server (visible digits)
    $/x
}

sub looks_like_common_email {

    my $email = shift || croak q/Value most be provided/;
    $email =~ /^
        \w+(?:\.\w+)*       # Username, can contain '.', but cant end with
        @                   # at
        (?:[A-Z0-9-]+\.)+   # Server, can contain alphanumeric digits and '-'
        [A-Z]{2,6}          # Final part of servername, 2 to 6 letters
    $/ix
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate::Email - A e-mail validating module.

=head1 SYNOPSIS

Function-oriented module capable of validating the format of any email, or only the common ones.

=head1 UTILITIES

=over 4

=item Any E-mail

    use Data::Format::Validate::Email 'looks_like_any_email';

    looks_like_any_email 'rozcovo@cpan.org';    # returns 1
    looks_like_any_email 'rozcovo@cpan. org';   # returns 0

=item Common E-mail

    use Data::Format::Validate::Email 'looks_like_common_email';

    looks_like_common_email 'rozcovo@cpan.org';     # returns 1
    looks_like_common_email 'rozcovo.@cpan.org';    # returns 0

=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/Email.pm

=head1 AUTHOR

Created by Israel Batista <rozcovo@cpan.org>

=cut
