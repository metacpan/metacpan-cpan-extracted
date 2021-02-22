package Data::Session::ID;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

use File::Spec;

use Hash::FieldHash ':all';

fieldhash my %id_length => 'id_length';

our $errstr  = '';
our $VERSION = '1.18';

# -----------------------------------------------

sub init
{
	my($class, $arg)  = @_;
	$$arg{debug}      ||= 0;
	$$arg{id}         ||= 0;
	$$arg{id_base}    ||= 0; # For AutoIncrement (AI).
	$$arg{id_file}    ||= File::Spec -> catdir(File::Spec -> tmpdir, 'data.session.id'); # For AI.
	$$arg{id_length}  = 0;   # For UUID.
	$$arg{id_step}    ||= 1; # For AI.
	$$arg{no_flock}   ||= 0;
	$$arg{umask}      ||= 0660;
	$$arg{verbose}    ||= 0;

} # End of init.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::ID> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::ID> is the parent of all L<Data::Session::ID::*> modules.

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Session>.

=head1 Author

L<Data::Session> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
