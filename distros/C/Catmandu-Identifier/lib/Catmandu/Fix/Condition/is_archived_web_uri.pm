package Catmandu::Fix::Condition::is_archived_web_uri;

our $VERSION = '0.14';

use Catmandu::Sane;
use Moo;
use Data::Validate::URI;
use Memento::TimeTravel;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);
has date => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    my $date = $self->date;
    $date = [localtime]->[5] + 1900 unless defined($date) && length($date);

    "(is_value(${var}) && Data::Validate::URI::is_web_uri(${var}) && Memento::TimeTravel::find_mementos(${var},${date}))";
}

=head1 NAME

Catmandu::Fix::Condition::is_archived_web_uri - check of a field contains an HTTP or HTTPS URI which is archived in a web archive

=head1 SYNOPSIS

   # Check if an archived version is available for any year...
   if is_archived_web_uri(uri_field,'')
     ...
   else
     ...
   end

   # Check if an archived version is available for a year...
   if is_archived_web_uri(uri_field,2013)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
