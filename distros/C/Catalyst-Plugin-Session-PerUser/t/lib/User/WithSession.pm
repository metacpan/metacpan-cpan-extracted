package User::WithSession;
   use base qw/Catalyst::Plugin::Authentication::User::Hash/;

   sub supports {
       my ( $self, $feature ) = @_;

       $feature eq "session_data" || $self->SUPER::supports($feature);
   }
   
   sub get_session_data {
       return shift->{session_data};
   }
   
   sub store_session_data {
       my ( $self, $data ) = @_;
       return $self->{session_data} = $data;
   }
   
1;
