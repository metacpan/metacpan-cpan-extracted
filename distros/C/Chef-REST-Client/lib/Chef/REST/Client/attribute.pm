#--------------------------------------------------------------------#
# @class  : Chef::Rest::Client::attribute                            #
# @author : Bhavin Patel                                             #
#--------------------------------------------------------------------#

package Chef::REST::Client::attribute;
$Chef::REST::Client::attribute::VERSION = 1.0;

sub new
{
	my $class = shift;
	my $param = {@_};
	my $self = {};
	bless $self, $class;
	
	$self->key  ( $param->{'key'  });
	$self->value( $param->{'value'});

	return $self;
}

sub key   { $_[0]->{'key'  } = $_[1] if defined $_[1]; return $_[0]->{'key'  }; }
sub value { $_[0]->{'value'} = $_[1] if defined $_[1]; return $_[0]->{'value'}; }

1;

__DATA__

=pod

=head1 NAME 

Chef::REST::Client::attribute

=head1 VERSION

1.0

=head1 SYNOPSIS

use Chef::REST::Client::attribute;

  my $obj = new Chef::REST::Client::attribute( 'key' => $key, 'value' => $value );
     $obj->key;
     $obj->value;

=head1 DESCRIPTION

Chef attribute class. used internally

=head1 METHODS

=head2 Chef::REST::Client::attribute( key => $key , value => $value )

returns new object of class L<Chef::REST::Client::attribute> with %params

=head2 key ( $key )

get or set value for 'key'

=head2 value ($value )

get or set value for 'value'

=head1 KNOWN BUGS

=head1 SUPPORT

open a github ticket or email comments to Bhavin Patel <bpatel10@nyit.edu>

=head1 COPYRIGHT AND LICENSE

This Software is free to use , licensed under : The Artisic License 2.0 (GPL Compatible)

=cut