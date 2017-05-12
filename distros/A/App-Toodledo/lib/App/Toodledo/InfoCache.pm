package App::Toodledo::InfoCache;

use Moose;
use MooseX::Method::Signatures;
use YAML qw(LoadFile DumpFile);
use App::Toodledo::Util qw(debug);
use Log::Log4perl;
with 'MooseX::Log::Log4perl';

has filename        => ( is => 'rw', isa => 'Str', );
has password_ref    => ( is => 'rw', isa => 'HashRef[Str]',
		         default => sub { {} } );
has app_token_ref   => ( is => 'rw', isa => 'HashRef[Str]',
		         default => sub { {} } );
has default_user_id => ( is => 'rw', isa => 'Str' );


method new_from_file ( $class: Str $file! ) {
  if ( -r $file && -f $file)
  {
    my $ref = LoadFile( $file );
    my ($password_ref, $app_token_ref, $default_user_id)
      = @{$ref}{qw(passwords app_tokens default_user_id)};
    my $log = Log::Log4perl->get_logger();
    $log->debug("Loaded info cache from $file");
    return $class->new( filename        => $file,
			password_ref    => $password_ref,
			app_token_ref   => $app_token_ref,
			default_user_id => $default_user_id );
  }
  else
  {
    return $class->new( filename => $file );
  }
}


method save_to_file ( Str $filename! ) {
  my %params = ( passwords       => $self->password_ref,
	         app_tokens      => $self->app_token_ref,
	         default_user_id => $self->default_user_id );
  DumpFile( $filename, \%params );
}


method save () {
  $self->log->debug("test");
  $self->save_to_file( $self->filename );
}


1;

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

Store information for making calls easier.  Used for storing
username => password mapping and app_id => app_token mappings.

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
