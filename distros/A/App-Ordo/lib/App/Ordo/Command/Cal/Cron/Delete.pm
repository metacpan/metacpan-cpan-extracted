package App::Ordo::Command::Cal::Cron::Delete;
use Moo;
use feature qw(say);
extends 'App::Ordo::Command::Base';

use Term::ANSIColor qw(colored);

sub name    { "cal cron delete" }
sub summary { "Delete a cron expression from a calendar" }
sub usage   { "<cron-id>" }
sub aliases { ['cal cron rm'] }

sub option_spec {
   return {};
}

sub execute {
   my ( $self, $opt, $cron_id ) = @_;

   unless ( $cron_id && $cron_id =~ /^\d+$/ ) {
      say colored( ["bold red"], "Usage: cal cron delete <cron-id>" );
      say "Example: cal cron delete 13";
      return;
   }

   my $payload = {

      #        cal => $cal_name,
      id => $cron_id,
   };
   $payload->{force} = 1 if $opt->{force};

   my $res = $self->api->call( 'delete_cron', $payload );

   if ( $res->{success} ) {
      my $name    = $res->{cal};
      my $message = "Cron ID $cron_id removed from calendar";
      $message .= " $res->{cal}" if $res->{cal};
      say colored( ["bold green"], $message );
   }
   else {
      say colored( ["bold red"], "Failed to delete cron: " . ( $res->{message} || 'unknown error' ) );
   }
}

1;
