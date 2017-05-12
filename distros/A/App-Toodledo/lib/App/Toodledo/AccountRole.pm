package App::Toodledo::AccountRole;

use Moose::Role;

our $VERSION = '1.00';

has pro                 => (is => 'rw', isa => 'Int' );
has dateformat          => (is => 'rw', isa => 'Str' );
has timezone            => (is => 'rw', isa => 'Int' );
has hidemonths          => (is => 'rw', isa => 'Int' );
has hotlistpriority     => (is => 'rw', isa => 'Int' );
has hotlistduedate      => (is => 'rw', isa => 'Int' );
has hotliststar         => (is => 'rw', isa => 'Bool' );
has hotliststatus       => (is => 'rw', isa => 'Bool' );
has showtabnums         => (is => 'rw', isa => 'Bool' );
has lastedit_task       => (is => 'rw', isa => 'Int' );
has lastdelete_task     => (is => 'rw', isa => 'Int' );
has lastedit_folder     => (is => 'rw', isa => 'Int' );
has lastedit_context    => (is => 'rw', isa => 'Int' );
has lastedit_goal       => (is => 'rw', isa => 'Int' );
has lastedit_location   => (is => 'rw', isa => 'Int' );
has lastedit_notebook   => (is => 'rw', isa => 'Int' );
has lastdelete_notebook => (is => 'rw', isa => 'Int' );
has userid              => (is => 'rw', isa => 'Str' );
has alias               => (is => 'rw', isa => 'Str' );

no Moose;

1;

__END__

=head1 NAME

App::Toodledo::Account - internal attributes of an account.

=head1 SYNOPSIS

For internal L<App::Toodledo> use only.

=head1 DESCRIPTION

For internal L<App::Toodledo> use only.

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
