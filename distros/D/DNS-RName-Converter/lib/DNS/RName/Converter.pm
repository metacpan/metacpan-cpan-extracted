package DNS::RName::Converter;

use 5.006;
use strict;
use warnings;
use Data::Validate::Email qw(is_email);
use Carp qw/croak/;
use vars qw/$VERSION/;

$VERSION = '0.01';

sub new {
    my $class = shift;
    bless {},$class;
}

sub email_to_rname {
    my $self = shift;
    my $email = shift;

    if ( is_email($email) ) {
        my ($user,$tld) = split/\@/,$email;
        $user =~ s/\./\\./g;
        return $user. '.' .$tld . '.';

    } else {
        croak "you have input a wrong email address";
    }
}

sub rname_to_email {
    my $self = shift;
    my $rname = shift;
    $rname =~ s/\.$//;
    
    if ($rname =~  /^(.*?)(?<!\\)\.(.*)$/) {
        my $user = $1;
        my $tld = $2;
        $user =~ s/\\//g;
        return $user . '@' . $tld;

    } else {
        croak "you have input a wrong rname";
    }
}

1;

=head1 NAME

DNS::RName::Converter - converting between email and rname for DNS SOA record

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use DNS::RName::Converter;

    my $cvt = DNS::RName::Converter->new;
    my $rname = $cvt->email_to_rname($email);
    my $email = $cvt->rname_to_email($rname);


=head1 METHODS

=head2 new()

Initialize the object.

=head2 email_to_rname(email_address)

Convert the email address to the rName for SOA record.

=head2 rname_to_email(rName)

Convert the rName from SOA to the standard email address.


=head1 SEE ALSO

http://www.ripe.net/ripe/docs/ripe-203


=head1 AUTHOR

Ken Peng <yhpeng@cpan.org>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <yhpeng@cpan.org>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DNS::RName::Converter


=head1 COPYRIGHT & LICENSE

Copyright 2014 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

