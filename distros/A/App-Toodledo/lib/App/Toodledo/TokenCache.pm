package App::Toodledo::TokenCache;

use Moose;
use MooseX::Method::Signatures;
use YAML qw(LoadFile DumpFile);
with 'MooseX::Log::Log4perl';

has filename => ( is => 'rw', isa => 'Str' );

has token_info_ref => ( is => 'rw', isa => 'HashRef[App::Toodledo::TokenInfo]',
		        default => sub { {} } );

method new_from_file ( $class: Str $file! ) {
  if ( -r $file && -f $file )
  {
    my $token_info_ref = LoadFile( $file );
    $class->new->log->debug( "Loaded token cache from $file");
    _prune_deadwood( $token_info_ref );
    return $class->new( filename => $file, token_info_ref => $token_info_ref );
  }
  else
  {
    return $class->new( filename => $file );
  }
}


sub _prune_deadwood
{
  my $token_info_ref = shift;

  for my $key ( keys %$token_info_ref )
  {
    $token_info_ref->{$key}->is_still_good or delete $token_info_ref->{$key};
  }
}


method save_to_file ( Str $filename! ) {
  $self->log->debug("Saved token cache to $filename");
  DumpFile( $filename, $self->token_info_ref );
}


method save () {
  $self->save_to_file( $self->filename );
}


method add_token_info ( Str :$user_id!, Str :$app_id!, Str :$token! ) {
  my $key = $self->_make_key( $user_id, $app_id );
  my $token_info = App::Toodledo::TokenInfo->new( token => $token );
  $self->token_info_ref->{$key} = $token_info;
}


method valid_token ( Str :$user_id!, Str :$app_id! ) {
  my $key = $self->_make_key( $user_id, $app_id );
  my $token_info = $self->token_info_ref->{$key} or return;
  $token_info->is_still_good or return;
  $token_info;
}


method _make_key ( Str $user_id!, Str $app_id! ) {
  "$user_id.$app_id";
}


package App::Toodledo::TokenInfo;

use Moose;
use MooseX::Method::Signatures;
use MooseX::ClassAttribute;


class_has Max_Token_Life => ( is => 'rw', default => 3600 * 3 );  # 3 hours

has creation_time => ( is => 'rw', isa => 'Int', default => sub { time } );
has token         => ( is => 'rw', isa => 'Str' );


method is_still_good () {
  time - $self->creation_time < __PACKAGE__->Max_Token_Life;
}


1;

__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Peter Scott C<cpan at psdt.com>

=cut
