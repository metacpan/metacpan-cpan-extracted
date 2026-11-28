# Test origin: AI
use Test2::V0;

use File::Find qw/find/;

# Every code block in these modules' documentation must have a copy in an example test. Blocks match
# with all whitespace removed, so a copy may be indented or tidied differently.
my @COVERED = qw{
    DBIx::QuickORM::Manual
    DBIx::QuickORM::Manual::Quickstart
    DBIx::QuickORM::Manual::Joins
    DBIx::QuickORM::Manual::Aggregates
    DBIx::QuickORM::Manual::ForeignKeys
    DBIx::QuickORM::Manual::Background
    DBIx::QuickORM::Manual::BulkInsert
    DBIx::QuickORM::Manual::Transactions
    DBIx::QuickORM::Manual::Caching
    DBIx::QuickORM::Manual::Keys
    DBIx::QuickORM::Manual::Values
    DBIx::QuickORM::Manual::Errors
    DBIx::QuickORM::Manual::Classes
    DBIx::QuickORM::Manual::RowClasses
    DBIx::QuickORM::Manual::Types
    DBIx::QuickORM::Manual::Dialects
    DBIx::QuickORM::Manual::DBIC
    DBIx::QuickORM
    DBIx::QuickORM::Handle
    DBIx::QuickORM::Row
    DBIx::QuickORM::AggregateRow
    DBIx::QuickORM::JoinRow
    DBIx::QuickORM::Iterator
    DBIx::QuickORM::Txn
    DBIx::QuickORM::DSL
    DBIx::QuickORM::ORM
    DBIx::QuickORM::Value
    DBIx::QuickORM::Type::JSON
    DBIx::QuickORM::Type::UUID
    DBIx::QuickORM::Type::DateTime
    DBIx::QuickORM::Type::DateTime::Lazy
    DBIx::QuickORM::Role::Row
    DBIx::QuickORM::Role::Type
};

# Documentation blocks that are not code, with all whitespace removed (see normalize()).
my %SKIP = map { $_ => 1 } (
    'packageMy::Schema::Result::User;usebase\'DBIx::Class::Core\';__PACKAGE__->load_components(\'InflateColumn::DateTime\');__PACKAGE__->table(\'users\');__PACKAGE__->add_columns(id=>{data_type=>\'integer\',is_auto_increment=>1,},name=>{data_type=>\'text\'},email=>{data_type=>\'text\',is_nullable=>1,},prefs=>{data_type=>\'json\',is_nullable=>1,},referred_by=>{data_type=>\'integer\',is_nullable=>1,},#readbackaftercreate,likethekeycreated=>{data_type=>\'timestamp\',retrieve_on_insert=>1,},);__PACKAGE__->set_primary_key(\'id\');__PACKAGE__->has_many(posts=>\'My::Schema::Result::Post\',\'user_id\');1;',
    'packageMy::Schema::Result::Post;usebase\'DBIx::Class::Core\';__PACKAGE__->table(\'posts\');__PACKAGE__->add_columns(id=>{data_type=>\'integer\',is_auto_increment=>1,},user_id=>{data_type=>\'integer\'},title=>{data_type=>\'text\'},views=>{data_type=>\'integer\',default_value=>0,},);__PACKAGE__->set_primary_key(\'id\');__PACKAGE__->belongs_to(author=>\'My::Schema::Result::User\',\'user_id\');1;',
    'packageMy::Schema;usebase\'DBIx::Class::Schema\';__PACKAGE__->load_namespaces;1;',
    'my$schema=My::Schema->connect($dsn,$user,$pass,{AutoCommit=>1});$schema=My::Schema->connect(sub{DBI->connect($dsn,$user,$pass,{RaiseError=>1})});',
    'my$alice=$schema->resultset(\'User\')->create({name=>\'Alice\'});my$found=$schema->resultset(\'User\')->find($alice->id);my$bob=$schema->resultset(\'User\')->search({email=>\'bob@example.com\'})->single;my$name=$alice->name;$alice->name(\'AliceSmith\');$alice->update;#or$alice->update({name=>\'AliceSmith\'})$alice->discard_changes;$alice->delete;',
    'my$rs=$schema->resultset(\'Post\')->search({views=>{\'>\'=>5}},{order_by=>{-desc=>\'views\'},rows=>10,offset=>20,},);my$hellos=$rs->search({title=>{-like=>\'Hello%\'}});#ANDedontotheconditionmy$count=$rs->count;#appliesrowsandoffset:atmost10my@all=$rs->all;while(my$post=$rs->next){my$title=$post->title;}my$first=$rs->first;',
    'my@data=$schema->resultset(\'Post\')->search(undef,{result_class=>\'DBIx::Class::ResultClass::HashRefInflator\'},)->all;',
    'my$author=$post->author;#belongs_to:aResultobjectmy@posts=$author->posts;#has_many:therowsinlistcontextmy$rs=$author->posts;#aResultSetinscalarcontextmy$busy=$author->search_related(\'posts\',{views=>{\'>\'=>5}})->count;my$new=$author->create_related(\'posts\',{title=>\'New\'});',
    'my@posts=$schema->resultset(\'Post\')->search({\'author.name\'=>\'Alice\'},{prefetch=>\'author\',order_by=>\'me.id\',},);formy$post(@posts){my$title=$post->title;my$author=$post->author->name;#prefetched:nosecondquery}',
    '__PACKAGE__->load_components(\'InflateColumn::DateTime\');__PACKAGE__->add_columns(created=>{data_type=>\'timestamp\'});my$year=$alice->created->year;',
    '$schema->txn_do(sub{$schema->resultset(\'User\')->create({name=>\'Dave\'});});my$guard=$schema->txn_scope_guard;$schema->resultset(\'User\')->create({name=>\'Eve\'});$guard->commit;#rolledbackiftheguardgoesoutofscopefirst',
    '$schema->resultset(\'User\')->populate([{name=>\'Fay\'},{name=>\'Gus\'}]);my$changed=$schema->resultset(\'Post\')->search({views=>0})->update({views=>1});my$removed=$schema->resultset(\'Post\')->search({views=>{\'<\'=>0}})->delete;',
    'my$n=$schema->resultset(\'Post\')->count;my$top=$schema->resultset(\'Post\')->get_column(\'views\')->max;my@per_user=$schema->resultset(\'Post\')->search(undef,{select=>[\'user_id\',{count=>\'*\',-as=>\'posts\',},],as=>[\'user_id\',\'posts\'],group_by=>[\'user_id\'],});my$posts=$per_user[0]->get_column(\'posts\');',
    'my$first=$schema->resultset(\'User\')->find($id);my$second=$schema->resultset(\'User\')->find($id);#asecond,independentobject$first->update({name=>\'Ann\'});my$old=$second->name;#stillthename$secondread$second->update({email=>\'b@example.com\'});#writesonlyemail:bothchangessurvive$second->discard_changes;#nowAnn',
    'packageMy::Schema::Result::User;#theResultclassfromabovesubdisplay_name{my$self=shift;return$self->name.\'<\'.$self->email.\'>\';}',
    'my$ida=$schema->resultset(\'User\')->create({name=>\'Ida\',created=>\\\'NOW()\'});$schema->resultset(\'Post\')->search({id=>$post_id})->update({views=>\\[\'views+?\',2]});',
    '$schema->deploy;#CREATETABLEfromtheResultclasses',
);

# Where the copies live: the example tests, and the schema the Quickstart shows.
my @COPIES = ('t/lib/DBIx/QuickORM/Test/Examples.pm');
find({no_chdir => 1, wanted => sub { push @COPIES => $_ if m/\.t\z/ }}, grep { -d } 't/acceptance/examples', 't/acceptance/Manual');

sub slurp {
    my ($file) = @_;
    open(my $fh, '<', $file) or die "Could not read '$file': $!";
    local $/;
    return <$fh>;
}

sub normalize {
    my ($text) = @_;
    $text =~ s/\s+//g;
    return $text;
}

# The indented (verbatim) blocks of a file's POD. A blank line does not end a block.
sub code_blocks {
    my ($file) = @_;
    my (@blocks, $pod, $block);
    for my $line (split m/(?<=\n)/, slurp($file)) {
        if ($line =~ m/^=(\w+)/) {
            $pod = $1 ne 'cut';
        }
        elsif ($pod && $line =~ m/^\s+\S/) {
            $block .= $line;
            next;
        }
        elsif ($pod && defined($block) && $line !~ m/\S/) {
            next;
        }
        push @blocks => $block if defined $block;
        $block = undef;
    }
    push @blocks => $block if defined $block;
    return @blocks;
}

my $copies = join "\n" => map { normalize(slurp($_)) } @COPIES;

for my $module (@COVERED) {
    (my $file = "$module.pm") =~ s{::}{/}g;
    require $file;

    for my $block (code_blocks($INC{$file})) {
        my $code = normalize($block);
        next if $SKIP{$code};
        my ($first) = $block =~ m/^\s*(.*\S)/;
        ok(index($copies, $code) >= 0, "$module: an example test has a copy of '$first'") or diag("Missing:\n$block");
    }
}

done_testing;
