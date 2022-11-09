package Acme::Mitey::Cards::MOP;

use Moose ();
use Moose::Util ();
use Moose::Util::MetaRole ();
use Moose::Util::TypeConstraints ();
use constant { true => !!1, false => !!0 };

my $META_CLASS = do {
    package Acme::Mitey::Cards::MOP::Meta::Class;
    use Moose;
    extends 'Moose::Meta::Class';
    around _immutable_options => sub {
        my ( $next, $self, @args ) = ( shift, shift, @_ );
        return $self->$next( replace_constructor => 1, @args );
    };
    __PACKAGE__->meta->make_immutable;

    __PACKAGE__;
};

my $META_ROLE = do {
    package Acme::Mitey::Cards::MOP::Meta::Role;
    use Moose;
    extends 'Moose::Meta::Role';
    my $built_ins = qr/\A( DOES | does | __META__ | __FINALIZE_APPLICATION__ |
        CREATE_CLASS | APPLY_TO )\z/x;
    around get_method => sub {
        my ( $next, $self, $method_name ) = ( shift, shift, @_ );
        return if $method_name =~ $built_ins;
        return $self->$next( @_ );
    };
    around get_method_list => sub {
        my ( $next, $self ) = ( shift, shift );
        return grep !/$built_ins/, $self->$next( @_ );
    };
    around _get_local_methods => sub {
        my ( $next, $self ) = ( shift, shift );
        my %map = %{ $self->_full_method_map };
        return map $map{$_}, $self->get_method_list;
    };
    __PACKAGE__->meta->make_immutable;

    __PACKAGE__;
};

require "Acme/Mitey/Cards/Card.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Card", package => "Acme::Mitey::Cards::Card" );
    my %ATTR;
    $ATTR{"deck"} = Moose::Meta::Attribute->new( "deck",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Card.pm", line => "9", package => "Acme::Mitey::Cards::Card", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => true,
        init_arg => "deck",
        required => false,
        type_constraint => do { require Acme::Mitey::Cards::Types::Source; Acme::Mitey::Cards::Types::Source::Deck() },
        reader => "deck",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"deck"},
            name => "deck",
            body => \&Acme::Mitey::Cards::Card::deck,
            package_name => "Acme::Mitey::Cards::Card",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Card::deck", file => "lib/Acme/Mitey/Cards/Card.pm", line => "9", package => "Acme::Mitey::Cards::Card", toolkit => "Mite", type => "class" },
        );
        $ATTR{"deck"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"deck"} );
    };
    $ATTR{"reverse"} = Moose::Meta::Attribute->new( "reverse",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Card.pm", line => "19", package => "Acme::Mitey::Cards::Card", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "reverse",
        required => false,
        type_constraint => do { require Types::Standard; Types::Standard::Str() },
        reader => "reverse",
        builder => "_build_reverse",
        lazy => true,
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"reverse"},
            name => "reverse",
            body => \&Acme::Mitey::Cards::Card::reverse,
            package_name => "Acme::Mitey::Cards::Card",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Card::reverse", file => "lib/Acme/Mitey/Cards/Card.pm", line => "19", package => "Acme::Mitey::Cards::Card", toolkit => "Mite", type => "class" },
        );
        $ATTR{"reverse"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"reverse"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Card::meta,
            package_name => "Acme::Mitey::Cards::Card",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Card" );
}

require "Acme/Mitey/Cards/Card/Face.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Card::Face", package => "Acme::Mitey::Cards::Card::Face" );
    my %ATTR;
    $ATTR{"suit"} = Moose::Meta::Attribute->new( "suit",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Card/Face.pm", line => "13", package => "Acme::Mitey::Cards::Card::Face", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "suit",
        required => true,
        type_constraint => do { require Acme::Mitey::Cards::Types::Source; Acme::Mitey::Cards::Types::Source::Suit() },
        coerce => true,
        reader => "suit",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"suit"},
            name => "suit",
            body => \&Acme::Mitey::Cards::Card::Face::suit,
            package_name => "Acme::Mitey::Cards::Card::Face",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Card::Face::suit", file => "lib/Acme/Mitey/Cards/Card/Face.pm", line => "13", package => "Acme::Mitey::Cards::Card::Face", toolkit => "Mite", type => "class" },
        );
        $ATTR{"suit"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"suit"} );
    };
    $ATTR{"face"} = Moose::Meta::Attribute->new( "face",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Card/Face.pm", line => "20", package => "Acme::Mitey::Cards::Card::Face", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "face",
        required => true,
        type_constraint => do { require Acme::Mitey::Cards::Types::Source; Acme::Mitey::Cards::Types::Source::Character() },
        reader => "face",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"face"},
            name => "face",
            body => \&Acme::Mitey::Cards::Card::Face::face,
            package_name => "Acme::Mitey::Cards::Card::Face",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Card::Face::face", file => "lib/Acme/Mitey/Cards/Card/Face.pm", line => "20", package => "Acme::Mitey::Cards::Card::Face", toolkit => "Mite", type => "class" },
        );
        $ATTR{"face"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"face"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Card::Face::meta,
            package_name => "Acme::Mitey::Cards::Card::Face",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Card::Face" );
}

require "Acme/Mitey/Cards/Card/Joker.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Card::Joker", package => "Acme::Mitey::Cards::Card::Joker" );
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Card::Joker::meta,
            package_name => "Acme::Mitey::Cards::Card::Joker",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Card::Joker" );
}

require "Acme/Mitey/Cards/Card/Numeric.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Card::Numeric", package => "Acme::Mitey::Cards::Card::Numeric" );
    my %ATTR;
    $ATTR{"suit"} = Moose::Meta::Attribute->new( "suit",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Card/Numeric.pm", line => "13", package => "Acme::Mitey::Cards::Card::Numeric", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "suit",
        required => true,
        type_constraint => do { require Acme::Mitey::Cards::Types::Source; Acme::Mitey::Cards::Types::Source::Suit() },
        coerce => true,
        reader => "suit",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"suit"},
            name => "suit",
            body => \&Acme::Mitey::Cards::Card::Numeric::suit,
            package_name => "Acme::Mitey::Cards::Card::Numeric",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Card::Numeric::suit", file => "lib/Acme/Mitey/Cards/Card/Numeric.pm", line => "13", package => "Acme::Mitey::Cards::Card::Numeric", toolkit => "Mite", type => "class" },
        );
        $ATTR{"suit"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"suit"} );
    };
    $ATTR{"number"} = Moose::Meta::Attribute->new( "number",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Card/Numeric.pm", line => "20", package => "Acme::Mitey::Cards::Card::Numeric", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "number",
        required => true,
        type_constraint => do { require Acme::Mitey::Cards::Types::Source; Acme::Mitey::Cards::Types::Source::CardNumber() },
        coerce => true,
        reader => "number",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"number"},
            name => "number",
            body => \&Acme::Mitey::Cards::Card::Numeric::number,
            package_name => "Acme::Mitey::Cards::Card::Numeric",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Card::Numeric::number", file => "lib/Acme/Mitey/Cards/Card/Numeric.pm", line => "20", package => "Acme::Mitey::Cards::Card::Numeric", toolkit => "Mite", type => "class" },
        );
        $ATTR{"number"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"number"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Card::Numeric::meta,
            package_name => "Acme::Mitey::Cards::Card::Numeric",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Card::Numeric" );
}

require "Acme/Mitey/Cards/Deck.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Deck", package => "Acme::Mitey::Cards::Deck" );
    my %ATTR;
    $ATTR{"reverse"} = Moose::Meta::Attribute->new( "reverse",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Deck.pm", line => "17", package => "Acme::Mitey::Cards::Deck", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "reverse",
        required => false,
        type_constraint => do { require Types::Common::String; Types::Common::String::NonEmptyStr() },
        reader => "reverse",
        default => "plain",
        lazy => false,
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"reverse"},
            name => "reverse",
            body => \&Acme::Mitey::Cards::Deck::reverse,
            package_name => "Acme::Mitey::Cards::Deck",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Deck::reverse", file => "lib/Acme/Mitey/Cards/Deck.pm", line => "17", package => "Acme::Mitey::Cards::Deck", toolkit => "Mite", type => "class" },
        );
        $ATTR{"reverse"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"reverse"} );
    };
    $ATTR{"original_cards"} = Moose::Meta::Attribute->new( "original_cards",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Deck.pm", line => "23", package => "Acme::Mitey::Cards::Deck", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "original_cards",
        required => false,
        type_constraint => do { require Acme::Mitey::Cards::Types::Source; Acme::Mitey::Cards::Types::Source::CardArray() },
        reader => "original_cards",
        builder => "_build_original_cards",
        lazy => true,
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"original_cards"},
            name => "original_cards",
            body => \&Acme::Mitey::Cards::Deck::original_cards,
            package_name => "Acme::Mitey::Cards::Deck",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Deck::original_cards", file => "lib/Acme/Mitey/Cards/Deck.pm", line => "23", package => "Acme::Mitey::Cards::Deck", toolkit => "Mite", type => "class" },
        );
        $ATTR{"original_cards"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"original_cards"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Deck::meta,
            package_name => "Acme::Mitey::Cards::Deck",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Deck" );
}

require "Acme/Mitey/Cards/Hand.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Hand", package => "Acme::Mitey::Cards::Hand" );
    my %ATTR;
    $ATTR{"owner"} = Moose::Meta::Attribute->new( "owner",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Hand.pm", line => "11", package => "Acme::Mitey::Cards::Hand", toolkit => "Mite", type => "class" },
        is => "rw",
        weak_ref => false,
        init_arg => "owner",
        required => false,
        type_constraint => do { require Types::Standard; Types::Standard::Str() | Types::Standard::Object() },
        accessor => "owner",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'accessor',
            attribute => $ATTR{"owner"},
            name => "owner",
            body => \&Acme::Mitey::Cards::Hand::owner,
            package_name => "Acme::Mitey::Cards::Hand",
            definition_context => { context => "has declaration", description => "accessor Acme::Mitey::Cards::Hand::owner", file => "lib/Acme/Mitey/Cards/Hand.pm", line => "11", package => "Acme::Mitey::Cards::Hand", toolkit => "Mite", type => "class" },
        );
        $ATTR{"owner"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"owner"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Hand::meta,
            package_name => "Acme::Mitey::Cards::Hand",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Hand" );
}

require "Acme/Mitey/Cards/Set.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Set", package => "Acme::Mitey::Cards::Set" );
    my %ATTR;
    $ATTR{"cards"} = Moose::Meta::Attribute->new( "cards",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Set.pm", line => "11", package => "Acme::Mitey::Cards::Set", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "cards",
        required => false,
        type_constraint => do { require Acme::Mitey::Cards::Types::Source; Acme::Mitey::Cards::Types::Source::CardArray() },
        reader => "cards",
        builder => "_build_cards",
        lazy => true,
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"cards"},
            name => "cards",
            body => \&Acme::Mitey::Cards::Set::cards,
            package_name => "Acme::Mitey::Cards::Set",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Set::cards", file => "lib/Acme/Mitey/Cards/Set.pm", line => "11", package => "Acme::Mitey::Cards::Set", toolkit => "Mite", type => "class" },
        );
        $ATTR{"cards"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"cards"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Set::meta,
            package_name => "Acme::Mitey::Cards::Set",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Set" );
}

require "Acme/Mitey/Cards/Suit.pm";

{
    my $PACKAGE = $META_CLASS->initialize( "Acme::Mitey::Cards::Suit", package => "Acme::Mitey::Cards::Suit" );
    my %ATTR;
    $ATTR{"name"} = Moose::Meta::Attribute->new( "name",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Suit.pm", line => "9", package => "Acme::Mitey::Cards::Suit", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "name",
        required => true,
        type_constraint => do { require Types::Common::String; Types::Common::String::NonEmptyStr() },
        reader => "name",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"name"},
            name => "name",
            body => \&Acme::Mitey::Cards::Suit::name,
            package_name => "Acme::Mitey::Cards::Suit",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Suit::name", file => "lib/Acme/Mitey/Cards/Suit.pm", line => "9", package => "Acme::Mitey::Cards::Suit", toolkit => "Mite", type => "class" },
        );
        $ATTR{"name"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"name"} );
    };
    $ATTR{"abbreviation"} = Moose::Meta::Attribute->new( "abbreviation",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Suit.pm", line => "19", package => "Acme::Mitey::Cards::Suit", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "abbreviation",
        required => false,
        type_constraint => do { require Types::Standard; Types::Standard::Str() },
        reader => "abbreviation",
        builder => "_build_abbreviation",
        lazy => true,
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"abbreviation"},
            name => "abbreviation",
            body => \&Acme::Mitey::Cards::Suit::abbreviation,
            package_name => "Acme::Mitey::Cards::Suit",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Suit::abbreviation", file => "lib/Acme/Mitey/Cards/Suit.pm", line => "19", package => "Acme::Mitey::Cards::Suit", toolkit => "Mite", type => "class" },
        );
        $ATTR{"abbreviation"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"abbreviation"} );
    };
    $ATTR{"colour"} = Moose::Meta::Attribute->new( "colour",
        __hack_no_process_options => true,
        associated_class => $PACKAGE,
        definition_context => { context => "has declaration", file => "lib/Acme/Mitey/Cards/Suit.pm", line => "21", package => "Acme::Mitey::Cards::Suit", toolkit => "Mite", type => "class" },
        is => "ro",
        weak_ref => false,
        init_arg => "colour",
        required => true,
        type_constraint => do { require Types::Standard; Types::Standard::Str() },
        reader => "colour",
    );
    {
        my $ACCESSOR = Moose::Meta::Method::Accessor->new(
            accessor_type => 'reader',
            attribute => $ATTR{"colour"},
            name => "colour",
            body => \&Acme::Mitey::Cards::Suit::colour,
            package_name => "Acme::Mitey::Cards::Suit",
            definition_context => { context => "has declaration", description => "reader Acme::Mitey::Cards::Suit::colour", file => "lib/Acme/Mitey/Cards/Suit.pm", line => "21", package => "Acme::Mitey::Cards::Suit", toolkit => "Mite", type => "class" },
        );
        $ATTR{"colour"}->associate_method( $ACCESSOR );
        $PACKAGE->add_method( $ACCESSOR->name, $ACCESSOR );
    }
    do {
        no warnings 'redefine';
        local *Moose::Meta::Attribute::install_accessors = sub {};
        $PACKAGE->add_attribute( $ATTR{"colour"} );
    };
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&Acme::Mitey::Cards::Suit::meta,
            package_name => "Acme::Mitey::Cards::Suit",
        ),
    );
    Moose::Util::TypeConstraints::find_or_create_isa_type_constraint( "Acme::Mitey::Cards::Suit" );
}

Moose::Util::find_meta( "Acme::Mitey::Cards::Card::Face" )->superclasses( "Acme::Mitey::Cards::Card" );
Moose::Util::find_meta( "Acme::Mitey::Cards::Card::Joker" )->superclasses( "Acme::Mitey::Cards::Card" );
Moose::Util::find_meta( "Acme::Mitey::Cards::Card::Numeric" )->superclasses( "Acme::Mitey::Cards::Card" );
Moose::Util::find_meta( "Acme::Mitey::Cards::Deck" )->superclasses( "Acme::Mitey::Cards::Set" );
Moose::Util::find_meta( "Acme::Mitey::Cards::Hand" )->superclasses( "Acme::Mitey::Cards::Set" );

true;

