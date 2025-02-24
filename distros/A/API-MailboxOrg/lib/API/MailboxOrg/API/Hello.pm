package API::MailboxOrg::API::Hello;

# ABSTRACT: MailboxOrg::API::Hello

# ---
# This class is auto-generated by bin/get_mailbox_api.pl
# ---

use v5.24;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Enum Str Int InstanceOf ArrayRef);
use API::MailboxOrg::Types qw(HashRefRestricted Boolean);
use Params::ValidationCompiler qw(validation_for);

extends 'API::MailboxOrg::APIBase';

with 'MooX::Singleton';

use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '1.0.2'; # VERSION

my %validators = (

);


sub innerworld ($self, %params) {
    my $validator = $validators{'innerworld'};
    %params       = $validator->(%params) if $validator;

    my %opt = (needs_auth => 1);

    return $self->_request( 'hello.innerworld', \%params, \%opt );
}

sub world ($self, %params) {
    my $validator = $validators{'world'};
    %params       = $validator->(%params) if $validator;

    my %opt = ();

    return $self->_request( 'hello.world', \%params, \%opt );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::MailboxOrg::API::Hello - MailboxOrg::API::Hello

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

    use API::MailboxOrg;

    my $user     = '1234abc';
    my $password = '1234abc';

    my $api      = API::MailboxOrg->new(
        user     => $user,
        password => $password,
    );

=head1 METHODS

=head2 innerworld

Returns the string 'Hello Inner-World!' if called from a valid session

Available for admin, reseller, account, domain, mail

returns: string

    $api->hello->innerworld(%params);

=head2 world

Returns the string 'Hello World!'

returns: string

    $api->hello->world(%params);

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
