package App::Standup::Role::Date;
use Object::Pad;
use Time::Piece;

role Date {

  no warnings 'experimental';

  # For some reason, if we use localtime directly it doesn´t use Time::Piece:localtime one
  field $date :accessor :param { Time::Piece::localtime };
}


=head1 NAME

App::Standup::Role::Date - Date management for Standup::Diary

=head1 SYNOPSIS

  class App::Standup::Diary :does( Date ) { ... }

=head1 DESCRIPTION

It provides an L<Object::Pad> role with an only C<date> field based on
L<Time::Piece>.

Any class implementing C<App::Standup::Role::Date> have a C<$self->date> instance
field.

=cut
