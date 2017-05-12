package App::Rad::Plugin::ValuePriority;

use warnings;
use strict;

=head1 NAME

App::Rad::Plugin::ValuePriority - A Plugin to make it easy to get value from all acessors.

=head1 VERSION

Version 0.02

=head1 Snippet

    use App::Rad qw/ValuePriority/;

    sub command_1 {
       my $c = shift;
    
       $c->stash->{value_1}         = "Test 01";
       $c->default_value->{value_2} = "Test 02";
    
       return join " --- ", $c->value->{value_1}, $c->value->{value_2}, $c->value->{value_3};
       # It will print Test 01 --- Test 02 ---
       # but if you call program like this:
       # ./my_app.pl command_1 --value_2="Option 02" --value_3="Option 03"
       # it will print:
       # Test 01 --- Option 02 --- Option 03
    }
    
    sub command_2 {
       my $c = shift;
    
       $c->stash->{value_1}         = "Test 01";
       $c->default_value->{value_2} = "Test 02";
    
       $c->to_stash;
    
       return join " --- ", $c->stash->{value_1}, $c->stash->{value_2}, $c->stash->{value_3};
       # It will print Test 01 --- Test 02 ---                             
       # but if you call program like this:                                
       # ./my_app.pl command_2 --value_2="Option 02" --value_3="Option 03"
       # it will print:
       # Test 01 --- Option 02 --- Option 03                               
    }

=cut

our $VERSION = '0.02';

=head1 Methods

=head2 $c->load()

Internal func

=cut

sub load {
   my $c = shift;
   $c->set_priority(qw/options config stash default_value/);
}

=head2 $c->default_value()

It is a acessor. You use it to set and get some key/value pairs.

=cut

sub default_value {
   my $c     = shift;
   $c->{default_value}->{default_value} = {} unless exists $c->{default_value}->{default_value};
   $c->{default_value}->{default_value};
}

=head2 $c->set_priority()

It receives a ordered list of what should receive priority.
The options are: options, config, stash, default_value
And that is the default order.

=cut

sub set_priority {
   my $c    = shift;
   my @prio = @_;
   my @nprio;
   die((join ", ", @nprio), " are not recognized.$/")
      if scalar (@nprio = grep {not m/^(?:options|config|stash|default_value)$/} @prio);
   $c->{default_value}->{priority} = [@prio];

}

=head2 $c->get_priority()

As the name says, it return the priority order. As a arrayref

=cut

sub get_priority {
   my $c = shift;
   $c->load if not exists $c->{default_value};
   $c->{default_value}->{priority};
}

=head2 $c->to_stash()

it populate the $c->stash with the values obeying the setted order.

=cut

sub to_stash {
   my $c = shift;
   for my $key (keys %{ $c->value }) {
      $c->stash->{$key} = $c->value->{$key}
   }
}

=head2 $c->value()

Return the value obeying the setted order.

=cut

sub value {
   my $c    = shift;
   my $redo = shift;
   my $ret;

   $c->load if not exists $c->{default_value} or not exists $c->{default_value}->{"values"};

   for my $func (@{ $c->{default_value}->{priority} }) {
      my $turn = $c->$func;
      for my $key (keys %$turn) {
         next if exists $ret->{$key};# and defined $c->stash->{$key};
         $ret->{$key} = $turn->{$key} if exists $turn->{$key};
      }
   }
   $c->stash->{default_value}->{"values"} = $ret;
}



42
