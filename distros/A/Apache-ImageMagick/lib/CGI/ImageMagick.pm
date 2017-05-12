

package CGI::ImageMagick ;


sub new
	{
	my ($class, $args) = @_ ;

	my $self = { %$args } ;
	bless $self, $class ;
	}

sub filename { $_[0] -> {filename} = $_[1] if ($_[1]) ;return $_[0] -> {filename} ;  }

sub uri { return $_[0] -> {filename} }

sub finfo { return $_[0] -> {filename} }

sub args { if (wantarray) { return %{$_[0] -> {args}} } else { return join('&', %{$_[0] -> {args}}) } }

sub path_info { return $_[0] -> {path_info} }

sub dir_config { return $_[0] -> {$_[1]} } 
 
sub log_error { shift ; print STDERR @_, "\n" ; }

sub lookup_file 
	{ 
	my ($self, $file) = @_ ;

	my $subr = { file => $file } ;
	bless $subr, 'CGI::ImageMagick::SubRequest' ;
	
	return $subr ;
	}

package CGI::ImageMagick::SubRequest ;

sub content_type { return 'image/*' }
	
1 ;

__END__

