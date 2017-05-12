
package Apache::ASP::CGI::Table;

use Carp qw(confess);

=pod

=head1 NAME

  Apache::ASP::CGI::Table

=head1 DESCRIPTION

Layer for compatibility with Apache::Table objects 
while running in CGI or command line / test mode.

=cut

sub new {
    my $class = shift;
    bless {}, $class;
}

sub set { 
    my($self, $key, $value) = @_;
    defined($key) || confess("no key to set value $value");
    $self->{$key} = $value;
}

sub get { shift()->{shift()}; }
sub unset { delete shift()->{shift()} };
sub clear { %{shift()} = (); };
sub add {
    my($self, $name, $value) = @_;

    my $old_value = $self->{$name};
    if(ref $old_value) {
	push(@$old_value, $value);
    } elsif(defined $old_value) {
	$self->{$name} = [$old_value, $value];
    } else {
	$self->{$name} = $value;
    }
}

sub merge { die("merge not implemented"); }

1;
