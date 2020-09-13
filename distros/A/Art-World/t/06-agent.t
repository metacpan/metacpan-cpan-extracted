use Test::More;
SKIP: {
    ok "Not implemented";
# use Data::Dump::Tree;
# use Art::Agent;

# my $agent = Art::Agent.new;
# does-ok $agent, Art::Behavior::CRUD;

# for Art::Agent.^attributes {
#     if $_ ~~ Art::Behavior::CRUD {
#         ok $_ ~~ Art::Behavior::CRUD,
#         'Attribute does CRUD through is crud trait';
#     }
# }

# $agent = Art::Agent.new(
#     id => 123456789,
#     name => "Camelia Butterfly",
#     reputation => 10
# );

# my @attributes = Art::Agent.^attributes;

# ok @attributes[1] ~~ Art::Behavior::CRUD, 'attribute does CRUD through is crud trait';
# ok $agent.name eq "Camelia Butterfly", 'Agent name contain the right value';

# my @found;

# for @attributes -> $attr {
#     if $attr ~~ Art::Behavior::CRUD {
#         @found.push($attr);
#     }
# }

# ok @found.Int == 3,
# 'The found number of attributes in the class is correct';

# ok $agent.introspect-crud-attributes == @found,
# '.introspect-crud-attributes returns the right number of elements';

# ddt $agent.introspect-crud-attributes;

}
done_testing;
