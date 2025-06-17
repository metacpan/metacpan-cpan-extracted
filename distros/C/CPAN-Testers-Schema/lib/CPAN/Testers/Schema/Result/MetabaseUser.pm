package CPAN::Testers::Schema::Result::MetabaseUser;
our $VERSION = '0.028';
# ABSTRACT: Legacy user information from the Metabase

#pod =head1 SYNOPSIS
#pod
#pod     my $rs = $schema->resultset( 'MetabaseUser' );
#pod     my ( $row ) = $rs->search({ resource => $resource })->all;
#pod
#pod     say $row->fullname;
#pod     say $row->email;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This table stores the Metabase users so we can look up their name and e-mail
#pod when they send in reports.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'Result';
table 'metabase_user';

#pod =attr id
#pod
#pod The ID of the row in the database.
#pod
#pod =cut

primary_column id => {
    data_type => 'int',
    is_auto_increment => 1,
};

#pod =attr resource
#pod
#pod The Metabase GUID of the user. We use this to look the user up. Will be
#pod a UUID prefixed with C<metabase:user:>.
#pod
#pod =cut

unique_column resource => {
    data_type => 'char',
    size => 50,
    is_nullable => 0,
};

#pod =attr fullname
#pod
#pod The full name of the user.
#pod
#pod =cut

column fullname => {
    data_type => 'varchar',
    is_nullable => 0,
};

#pod =attr email
#pod
#pod The e-mail address of the user.
#pod
#pod =cut

column email => {
    data_type => 'varchar',
    is_nullable => 1,
};

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Result::MetabaseUser - Legacy user information from the Metabase

=head1 VERSION

version 0.028

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'MetabaseUser' );
    my ( $row ) = $rs->search({ resource => $resource })->all;

    say $row->fullname;
    say $row->email;

=head1 DESCRIPTION

This table stores the Metabase users so we can look up their name and e-mail
when they send in reports.

=head1 ATTRIBUTES

=head2 id

The ID of the row in the database.

=head2 resource

The Metabase GUID of the user. We use this to look the user up. Will be
a UUID prefixed with C<metabase:user:>.

=head2 fullname

The full name of the user.

=head2 email

The e-mail address of the user.

=head1 SEE ALSO

L<CPAN::Testers::Schema>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
