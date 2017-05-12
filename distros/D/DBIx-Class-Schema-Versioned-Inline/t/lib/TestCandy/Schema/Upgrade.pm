package TestCandy::Schema::Upgrade;

use base 'DBIx::Class::Schema::Versioned::Inline::Upgrade';
use DBIx::Class::Schema::Versioned::Inline::Upgrade qw/before after/;

before '0.002' => sub {
    my $schema = shift;
    my $rset = $schema->resultset('Foo')->search({ height => undef});
    $rset->update({ height => 20});
};

after '0.002' => sub {
    my $schema = shift;
    $schema->resultset('Bar')->create({ weight => 20 });
};

after '0.002' => sub {
    my $schema = shift;
    $schema->resultset('Foo')->create({ width => 30 });
};

after '0.003' => sub {
    my $schema = shift;
    $schema->resultset('Tree')->create({ width => 40 });
};

before '0.004' => sub {
    my $schema = shift;
    my $rset = $schema->resultset('Bar')->search({ age => undef });
    $rset->update({ age => 0});
};

1;
