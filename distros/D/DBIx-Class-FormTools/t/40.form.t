use Test::More;
use Data::Dump 'pp';

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 1);
}

ok(1);

# 
# INIT {
#     use lib 't/lib';
#     use_ok('Test');
# }
# 
# # Initialize database
# my $schema = Test->initialize;
# ok($schema, "Schema created");
# 
# my $helper = DBIx::Class::FormTools->new({ schema => $schema });
# ok($helper,"Helper object created");
# 
# # Create test objects in memory
# my $film = $schema->resultset('Film')->new({
#     title   => 'Office Space',
#     comment => 'Funny film',
# });
# my $actor = $schema->resultset('Actor')->new({
#     name   => 'Cartman',
# });
# 
# my $role = $schema->resultset('Role')->new({
# #    charater => 'The New guy',
# });
# 
# # Create form
# my $form = $helper->form({
#     action => 'http://localhost/dostuff',
#     method => 'post',
# });
# 
# 
# $form->add_object($film);
# $form->add_object($actor);
# $form->add_object($role);
# 
# # print pp($form);
# 
# 
# print $form->start_tag . "\n";
# 
# print pp($form->tags) . "\n";
# 
# print "[". pp($form->field->input) ."]\n";

# --

# print $form->field->input->text(
#     $film => 'title', { class => 'film' }
# )->as_xml;
# 
# print $form->field('Input::Text')
#     $film => 'title', { class => 'film' }
# )->as_xml;


#print $form->field->textarea(
#    $film => 'comment', { class => 'film', cols => 10, rows => 5 }
#)->as_xml;
#
#print $form->field->input->text(
#    $actor => 'name', { class => 'actor' }
#)->as_xml;
#print $form->field->input->text(
#    $actor => 'charater', { class => 'actor' }
#)->as_xml;
#
#print $form->field->input->hidden(
#    $role => 'charater',
#    { value => 'kid', class => 'actor' },
#    { film_id => $film, actor_id => $actor }
#)->as_xml;
#
#
# print $form->end_tag . "\n";

