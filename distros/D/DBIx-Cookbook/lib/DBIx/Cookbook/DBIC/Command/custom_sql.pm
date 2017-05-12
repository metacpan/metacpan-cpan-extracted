package DBIx::Cookbook::DBIC::Command::custom_sql;
use Moose;
extends qw(MooseX::App::Cmd::Command);

use Data::Dump;

#use DBIx::Cookbook::DBIC::CustomSQL;


=for comment

[16:47] <boghead> metaperl: look at the documentation for ->load_namespaces.  It allows you to specify custom resultset namespaces
[16:47] <boghead> metaperl: You can also explicitly set your resultset in the result class
[16:49] <boghead> metaperl: by the way, I applied your patch and checked it into the trunk
[16:49] <boghead> metaperl++
[16:49] <metaperl> ok, that's nice
[16:50] <metaperl> by "in the Result class", those are auto-generated if I use ::Loader right? that's what I'm trying to avoid
[16:51] <boghead> there are several ways to do it
[16:52] <metaperl> well let's terminate this discussion as I'm leaving in 9 minutes
[16:52] <boghead> you may be able to change your Schema::Loader config to force a different resultset even
[16:52] <metaperl> hm
[16:52] <boghead> or you could stick some custom code in the generated files, in the section allowing custom code
[16:53] <metaperl> yes that's what I dont like doing at all :)
[16:55] <boghead> default_resultset_class, and resultset_namespace parameters to load_namespaces are probably what you want then

=cut

sub execute {
  my ($self, $opt, $args) = @_;

  my $rs = do {
    my $where = {};
    my $attr  = { bind => [ 'C%' ] };
    $self->app->schema->resultset('OverdueDVDs')->search($where, $attr);
  };

  my $row = $rs->single;

  my %data = $row->get_columns;
  warn Data::Dump::dump(\%data);

}

1;
