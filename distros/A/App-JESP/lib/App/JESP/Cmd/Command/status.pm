package App::JESP::Cmd::Command::status;
$App::JESP::Cmd::Command::status::VERSION = '0.010';
use base qw/App::JESP::Cmd::CommandJESP/;
use strict; use warnings;
use Log::Any qw/$log/;

=head1 NAME

App::JESP::Cmd::Command::status - Shows the status of patches

=cut

=head2 options

See superclass L<App::JESP::Cmd::CommandJESP>

=head2 abstract

=head2 description

=head2 execute

See L<App::Cmd>

=cut

sub options{
    my ($class, $app) = @_;
    return ();
}


sub abstract { "Show the status of the plan VS the DB" }
sub description { "Show the status of the patches in the plan versus the patches recorded in the DB" }
sub execute {
    my ($self, $opts, $args) = @_;
    my $status = $self->jesp->status( $opts );
    foreach my $patch ( @{$status->{plan_patches} }){
        print "Patch '".$patch->id()."'";
        if( $patch->applied_datetime() ){
            print " Applied on ".$patch->applied_datetime();
        }else{
            print " - not applied yet - ";
        }
        print "\n";
    }
    foreach my $orphan ( @{$status->{plan_orphans}} ){
        print "ORPHANED: '".$orphan."'   Gone from plan?!?\n";
    }
}

1;
