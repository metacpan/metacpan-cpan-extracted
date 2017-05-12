use strict;
use utf8;
use Test::More qw[no_plan];
use_ok 'Data::Message';

my $text = do { local $/; <DATA> };

{
    my $msg = Data::Message->new($text);
    isa_ok $msg, 'Data::Message';
    my $as_text = $msg->as_string;
    unlike $as_text, qr/text\n.+text\n/, 'is not folded';
}

{
    my $msg = Data::Message->new($text, fold => 1);
    isa_ok $msg, 'Data::Message';
    my $as_text = $msg->as_string;
    unlike $as_text, qr/text\n.+text\n/, 'is folded';
}

{
    my $msg = Data::Message->new($text);
    isa_ok $msg, 'Data::Message';
    eval { $msg->header_set("Hell¿" => "Testing") };
    ok !$@, 'non-ascii header names did not complain';
}

{
    my $msg = Data::Message->new($text, grouchy => 1);
    isa_ok $msg, 'Data::Message';
    eval { $msg->header_set("Hell¿" => "Testing") };
    ok $@, "non-ascii header names did complain";

    my $msg2 = Data::Message->new($text, grouchy => undef);
    isa_ok $msg2, 'Data::Message';
    eval { $msg2->header_set("Hell¿" => "Testing") };
    ok !$@, "non-ascii header names did not complain";
}

__END__
Key: value
Key2: value two
LongKey: text text text text text text text text text text text text text text text text text text text text text text text text text text text
Final: 1
