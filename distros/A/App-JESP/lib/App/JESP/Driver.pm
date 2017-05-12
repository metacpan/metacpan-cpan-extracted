package App::JESP::Driver;
$App::JESP::Driver::VERSION = '0.008';
use Moose;

=head1 NAME

App::JESP::Driver - DB Specific stuff superclass.

=cut

use Log::Any qw/$log/;

has 'jesp' => ( is => 'ro' , isa => 'App::JESP', required => 1, weak_ref => 1);

=head2 apply_patch

Applies the given L<App::JESP::Patch> to the database. Dies in case of error.

You do NOT need to implement that in subclasses.

Usage:

  $this->apply_patch( $patch );

=cut

sub apply_patch{
    my ($self, $patch) = @_;
    $log->info("Applying patch ".$patch->id());
    if( my $sql = $patch->sql() ){
        $log->trace("Patch is SQL='$sql'");
        return $self->apply_sql( $sql );
    }
}

=head2 apply_sql

Databases and their drivers vary a lot when it comes
to apply SQL patches. Some of them are just fine with sending
a blog of SQL to the driver, even when it contains multiple
statements and trigger or procedure, function definitions.

Some of them require a specific implementation.

This is the default implementation that just use the underlying DB
connection to send the patch SQL content.

=cut

sub apply_sql{
    my ($self, $sql) = @_;
    my $dbh = $self->jesp()->get_dbh()->();
    my $ret = $dbh->do( $sql );
    return  defined($ret) ? $ret : confess( $dbh->errstr() );
}

__PACKAGE__->meta()->make_immutable();
