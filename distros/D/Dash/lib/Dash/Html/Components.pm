package Dash::Html::Components;
use strict;
use warnings;
use Module::Load;

sub A {
    shift @_;
    load Dash::Html::Components::A;
    if ( Dash::Html::Components::A->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::A->new(@_);
}

sub Abbr {
    shift @_;
    load Dash::Html::Components::Abbr;
    if ( Dash::Html::Components::Abbr->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Abbr->new(@_);
}

sub Acronym {
    shift @_;
    load Dash::Html::Components::Acronym;
    if ( Dash::Html::Components::Acronym->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Acronym->new(@_);
}

sub Address {
    shift @_;
    load Dash::Html::Components::Address;
    if ( Dash::Html::Components::Address->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Address->new(@_);
}

sub Area {
    shift @_;
    load Dash::Html::Components::Area;
    if ( Dash::Html::Components::Area->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Area->new(@_);
}

sub Article {
    shift @_;
    load Dash::Html::Components::Article;
    if ( Dash::Html::Components::Article->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Article->new(@_);
}

sub Aside {
    shift @_;
    load Dash::Html::Components::Aside;
    if ( Dash::Html::Components::Aside->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Aside->new(@_);
}

sub Audio {
    shift @_;
    load Dash::Html::Components::Audio;
    if ( Dash::Html::Components::Audio->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Audio->new(@_);
}

sub B {
    shift @_;
    load Dash::Html::Components::B;
    if ( Dash::Html::Components::B->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::B->new(@_);
}

sub Base {
    shift @_;
    load Dash::Html::Components::Base;
    if ( Dash::Html::Components::Base->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Base->new(@_);
}

sub Basefont {
    shift @_;
    load Dash::Html::Components::Basefont;
    if ( Dash::Html::Components::Basefont->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Basefont->new(@_);
}

sub Bdi {
    shift @_;
    load Dash::Html::Components::Bdi;
    if ( Dash::Html::Components::Bdi->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Bdi->new(@_);
}

sub Bdo {
    shift @_;
    load Dash::Html::Components::Bdo;
    if ( Dash::Html::Components::Bdo->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Bdo->new(@_);
}

sub Big {
    shift @_;
    load Dash::Html::Components::Big;
    if ( Dash::Html::Components::Big->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Big->new(@_);
}

sub Blink {
    shift @_;
    load Dash::Html::Components::Blink;
    if ( Dash::Html::Components::Blink->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Blink->new(@_);
}

sub Blockquote {
    shift @_;
    load Dash::Html::Components::Blockquote;
    if ( Dash::Html::Components::Blockquote->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Blockquote->new(@_);
}

sub Br {
    shift @_;
    load Dash::Html::Components::Br;
    if ( Dash::Html::Components::Br->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Br->new(@_);
}

sub Button {
    shift @_;
    load Dash::Html::Components::Button;
    if ( Dash::Html::Components::Button->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Button->new(@_);
}

sub Canvas {
    shift @_;
    load Dash::Html::Components::Canvas;
    if ( Dash::Html::Components::Canvas->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Canvas->new(@_);
}

sub Caption {
    shift @_;
    load Dash::Html::Components::Caption;
    if ( Dash::Html::Components::Caption->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Caption->new(@_);
}

sub Center {
    shift @_;
    load Dash::Html::Components::Center;
    if ( Dash::Html::Components::Center->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Center->new(@_);
}

sub Cite {
    shift @_;
    load Dash::Html::Components::Cite;
    if ( Dash::Html::Components::Cite->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Cite->new(@_);
}

sub Code {
    shift @_;
    load Dash::Html::Components::Code;
    if ( Dash::Html::Components::Code->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Code->new(@_);
}

sub Col {
    shift @_;
    load Dash::Html::Components::Col;
    if ( Dash::Html::Components::Col->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Col->new(@_);
}

sub Colgroup {
    shift @_;
    load Dash::Html::Components::Colgroup;
    if ( Dash::Html::Components::Colgroup->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Colgroup->new(@_);
}

sub Command {
    shift @_;
    load Dash::Html::Components::Command;
    if ( Dash::Html::Components::Command->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Command->new(@_);
}

sub Content {
    shift @_;
    load Dash::Html::Components::Content;
    if ( Dash::Html::Components::Content->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Content->new(@_);
}

sub Data {
    shift @_;
    load Dash::Html::Components::Data;
    if ( Dash::Html::Components::Data->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Data->new(@_);
}

sub Datalist {
    shift @_;
    load Dash::Html::Components::Datalist;
    if ( Dash::Html::Components::Datalist->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Datalist->new(@_);
}

sub Dd {
    shift @_;
    load Dash::Html::Components::Dd;
    if ( Dash::Html::Components::Dd->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Dd->new(@_);
}

sub Del {
    shift @_;
    load Dash::Html::Components::Del;
    if ( Dash::Html::Components::Del->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Del->new(@_);
}

sub Details {
    shift @_;
    load Dash::Html::Components::Details;
    if ( Dash::Html::Components::Details->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Details->new(@_);
}

sub Dfn {
    shift @_;
    load Dash::Html::Components::Dfn;
    if ( Dash::Html::Components::Dfn->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Dfn->new(@_);
}

sub Dialog {
    shift @_;
    load Dash::Html::Components::Dialog;
    if ( Dash::Html::Components::Dialog->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Dialog->new(@_);
}

sub Div {
    shift @_;
    load Dash::Html::Components::Div;
    if ( Dash::Html::Components::Div->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Div->new(@_);
}

sub Dl {
    shift @_;
    load Dash::Html::Components::Dl;
    if ( Dash::Html::Components::Dl->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Dl->new(@_);
}

sub Dt {
    shift @_;
    load Dash::Html::Components::Dt;
    if ( Dash::Html::Components::Dt->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Dt->new(@_);
}

sub Element {
    shift @_;
    load Dash::Html::Components::Element;
    if ( Dash::Html::Components::Element->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Element->new(@_);
}

sub Em {
    shift @_;
    load Dash::Html::Components::Em;
    if ( Dash::Html::Components::Em->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Em->new(@_);
}

sub Embed {
    shift @_;
    load Dash::Html::Components::Embed;
    if ( Dash::Html::Components::Embed->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Embed->new(@_);
}

sub Fieldset {
    shift @_;
    load Dash::Html::Components::Fieldset;
    if ( Dash::Html::Components::Fieldset->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Fieldset->new(@_);
}

sub Figcaption {
    shift @_;
    load Dash::Html::Components::Figcaption;
    if ( Dash::Html::Components::Figcaption->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Figcaption->new(@_);
}

sub Figure {
    shift @_;
    load Dash::Html::Components::Figure;
    if ( Dash::Html::Components::Figure->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Figure->new(@_);
}

sub Font {
    shift @_;
    load Dash::Html::Components::Font;
    if ( Dash::Html::Components::Font->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Font->new(@_);
}

sub Footer {
    shift @_;
    load Dash::Html::Components::Footer;
    if ( Dash::Html::Components::Footer->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Footer->new(@_);
}

sub Form {
    shift @_;
    load Dash::Html::Components::Form;
    if ( Dash::Html::Components::Form->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Form->new(@_);
}

sub Frame {
    shift @_;
    load Dash::Html::Components::Frame;
    if ( Dash::Html::Components::Frame->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Frame->new(@_);
}

sub Frameset {
    shift @_;
    load Dash::Html::Components::Frameset;
    if ( Dash::Html::Components::Frameset->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Frameset->new(@_);
}

sub H1 {
    shift @_;
    load Dash::Html::Components::H1;
    if ( Dash::Html::Components::H1->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::H1->new(@_);
}

sub H2 {
    shift @_;
    load Dash::Html::Components::H2;
    if ( Dash::Html::Components::H2->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::H2->new(@_);
}

sub H3 {
    shift @_;
    load Dash::Html::Components::H3;
    if ( Dash::Html::Components::H3->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::H3->new(@_);
}

sub H4 {
    shift @_;
    load Dash::Html::Components::H4;
    if ( Dash::Html::Components::H4->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::H4->new(@_);
}

sub H5 {
    shift @_;
    load Dash::Html::Components::H5;
    if ( Dash::Html::Components::H5->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::H5->new(@_);
}

sub H6 {
    shift @_;
    load Dash::Html::Components::H6;
    if ( Dash::Html::Components::H6->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::H6->new(@_);
}

sub Header {
    shift @_;
    load Dash::Html::Components::Header;
    if ( Dash::Html::Components::Header->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Header->new(@_);
}

sub Hgroup {
    shift @_;
    load Dash::Html::Components::Hgroup;
    if ( Dash::Html::Components::Hgroup->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Hgroup->new(@_);
}

sub Hr {
    shift @_;
    load Dash::Html::Components::Hr;
    if ( Dash::Html::Components::Hr->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Hr->new(@_);
}

sub I {
    shift @_;
    load Dash::Html::Components::I;
    if ( Dash::Html::Components::I->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::I->new(@_);
}

sub Iframe {
    shift @_;
    load Dash::Html::Components::Iframe;
    if ( Dash::Html::Components::Iframe->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Iframe->new(@_);
}

sub Img {
    shift @_;
    load Dash::Html::Components::Img;
    if ( Dash::Html::Components::Img->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Img->new(@_);
}

sub Ins {
    shift @_;
    load Dash::Html::Components::Ins;
    if ( Dash::Html::Components::Ins->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Ins->new(@_);
}

sub Isindex {
    shift @_;
    load Dash::Html::Components::Isindex;
    if ( Dash::Html::Components::Isindex->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Isindex->new(@_);
}

sub Kbd {
    shift @_;
    load Dash::Html::Components::Kbd;
    if ( Dash::Html::Components::Kbd->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Kbd->new(@_);
}

sub Keygen {
    shift @_;
    load Dash::Html::Components::Keygen;
    if ( Dash::Html::Components::Keygen->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Keygen->new(@_);
}

sub Label {
    shift @_;
    load Dash::Html::Components::Label;
    if ( Dash::Html::Components::Label->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Label->new(@_);
}

sub Legend {
    shift @_;
    load Dash::Html::Components::Legend;
    if ( Dash::Html::Components::Legend->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Legend->new(@_);
}

sub Li {
    shift @_;
    load Dash::Html::Components::Li;
    if ( Dash::Html::Components::Li->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Li->new(@_);
}

sub Link {
    shift @_;
    load Dash::Html::Components::Link;
    if ( Dash::Html::Components::Link->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Link->new(@_);
}

sub Listing {
    shift @_;
    load Dash::Html::Components::Listing;
    if ( Dash::Html::Components::Listing->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Listing->new(@_);
}

sub Main {
    shift @_;
    load Dash::Html::Components::Main;
    if ( Dash::Html::Components::Main->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Main->new(@_);
}

sub MapEl {
    shift @_;
    load Dash::Html::Components::MapEl;
    if ( Dash::Html::Components::MapEl->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::MapEl->new(@_);
}

sub Mark {
    shift @_;
    load Dash::Html::Components::Mark;
    if ( Dash::Html::Components::Mark->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Mark->new(@_);
}

sub Marquee {
    shift @_;
    load Dash::Html::Components::Marquee;
    if ( Dash::Html::Components::Marquee->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Marquee->new(@_);
}

sub Meta {
    shift @_;
    load Dash::Html::Components::Meta;
    if ( Dash::Html::Components::Meta->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Meta->new(@_);
}

sub Meter {
    shift @_;
    load Dash::Html::Components::Meter;
    if ( Dash::Html::Components::Meter->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Meter->new(@_);
}

sub Multicol {
    shift @_;
    load Dash::Html::Components::Multicol;
    if ( Dash::Html::Components::Multicol->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Multicol->new(@_);
}

sub Nav {
    shift @_;
    load Dash::Html::Components::Nav;
    if ( Dash::Html::Components::Nav->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Nav->new(@_);
}

sub Nextid {
    shift @_;
    load Dash::Html::Components::Nextid;
    if ( Dash::Html::Components::Nextid->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Nextid->new(@_);
}

sub Nobr {
    shift @_;
    load Dash::Html::Components::Nobr;
    if ( Dash::Html::Components::Nobr->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Nobr->new(@_);
}

sub Noscript {
    shift @_;
    load Dash::Html::Components::Noscript;
    if ( Dash::Html::Components::Noscript->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Noscript->new(@_);
}

sub ObjectEl {
    shift @_;
    load Dash::Html::Components::ObjectEl;
    if ( Dash::Html::Components::ObjectEl->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::ObjectEl->new(@_);
}

sub Ol {
    shift @_;
    load Dash::Html::Components::Ol;
    if ( Dash::Html::Components::Ol->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Ol->new(@_);
}

sub Optgroup {
    shift @_;
    load Dash::Html::Components::Optgroup;
    if ( Dash::Html::Components::Optgroup->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Optgroup->new(@_);
}

sub Option {
    shift @_;
    load Dash::Html::Components::Option;
    if ( Dash::Html::Components::Option->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Option->new(@_);
}

sub Output {
    shift @_;
    load Dash::Html::Components::Output;
    if ( Dash::Html::Components::Output->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Output->new(@_);
}

sub P {
    shift @_;
    load Dash::Html::Components::P;
    if ( Dash::Html::Components::P->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::P->new(@_);
}

sub Param {
    shift @_;
    load Dash::Html::Components::Param;
    if ( Dash::Html::Components::Param->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Param->new(@_);
}

sub Picture {
    shift @_;
    load Dash::Html::Components::Picture;
    if ( Dash::Html::Components::Picture->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Picture->new(@_);
}

sub Plaintext {
    shift @_;
    load Dash::Html::Components::Plaintext;
    if ( Dash::Html::Components::Plaintext->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Plaintext->new(@_);
}

sub Pre {
    shift @_;
    load Dash::Html::Components::Pre;
    if ( Dash::Html::Components::Pre->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Pre->new(@_);
}

sub Progress {
    shift @_;
    load Dash::Html::Components::Progress;
    if ( Dash::Html::Components::Progress->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Progress->new(@_);
}

sub Q {
    shift @_;
    load Dash::Html::Components::Q;
    if ( Dash::Html::Components::Q->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Q->new(@_);
}

sub Rb {
    shift @_;
    load Dash::Html::Components::Rb;
    if ( Dash::Html::Components::Rb->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Rb->new(@_);
}

sub Rp {
    shift @_;
    load Dash::Html::Components::Rp;
    if ( Dash::Html::Components::Rp->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Rp->new(@_);
}

sub Rt {
    shift @_;
    load Dash::Html::Components::Rt;
    if ( Dash::Html::Components::Rt->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Rt->new(@_);
}

sub Rtc {
    shift @_;
    load Dash::Html::Components::Rtc;
    if ( Dash::Html::Components::Rtc->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Rtc->new(@_);
}

sub Ruby {
    shift @_;
    load Dash::Html::Components::Ruby;
    if ( Dash::Html::Components::Ruby->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Ruby->new(@_);
}

sub S {
    shift @_;
    load Dash::Html::Components::S;
    if ( Dash::Html::Components::S->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::S->new(@_);
}

sub Samp {
    shift @_;
    load Dash::Html::Components::Samp;
    if ( Dash::Html::Components::Samp->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Samp->new(@_);
}

sub Script {
    shift @_;
    load Dash::Html::Components::Script;
    if ( Dash::Html::Components::Script->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Script->new(@_);
}

sub Section {
    shift @_;
    load Dash::Html::Components::Section;
    if ( Dash::Html::Components::Section->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Section->new(@_);
}

sub Select {
    shift @_;
    load Dash::Html::Components::Select;
    if ( Dash::Html::Components::Select->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Select->new(@_);
}

sub Shadow {
    shift @_;
    load Dash::Html::Components::Shadow;
    if ( Dash::Html::Components::Shadow->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Shadow->new(@_);
}

sub Slot {
    shift @_;
    load Dash::Html::Components::Slot;
    if ( Dash::Html::Components::Slot->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Slot->new(@_);
}

sub Small {
    shift @_;
    load Dash::Html::Components::Small;
    if ( Dash::Html::Components::Small->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Small->new(@_);
}

sub Source {
    shift @_;
    load Dash::Html::Components::Source;
    if ( Dash::Html::Components::Source->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Source->new(@_);
}

sub Spacer {
    shift @_;
    load Dash::Html::Components::Spacer;
    if ( Dash::Html::Components::Spacer->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Spacer->new(@_);
}

sub Span {
    shift @_;
    load Dash::Html::Components::Span;
    if ( Dash::Html::Components::Span->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Span->new(@_);
}

sub Strike {
    shift @_;
    load Dash::Html::Components::Strike;
    if ( Dash::Html::Components::Strike->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Strike->new(@_);
}

sub Strong {
    shift @_;
    load Dash::Html::Components::Strong;
    if ( Dash::Html::Components::Strong->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Strong->new(@_);
}

sub Sub {
    shift @_;
    load Dash::Html::Components::Sub;
    if ( Dash::Html::Components::Sub->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Sub->new(@_);
}

sub Summary {
    shift @_;
    load Dash::Html::Components::Summary;
    if ( Dash::Html::Components::Summary->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Summary->new(@_);
}

sub Sup {
    shift @_;
    load Dash::Html::Components::Sup;
    if ( Dash::Html::Components::Sup->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Sup->new(@_);
}

sub Table {
    shift @_;
    load Dash::Html::Components::Table;
    if ( Dash::Html::Components::Table->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Table->new(@_);
}

sub Tbody {
    shift @_;
    load Dash::Html::Components::Tbody;
    if ( Dash::Html::Components::Tbody->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Tbody->new(@_);
}

sub Td {
    shift @_;
    load Dash::Html::Components::Td;
    if ( Dash::Html::Components::Td->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Td->new(@_);
}

sub Template {
    shift @_;
    load Dash::Html::Components::Template;
    if ( Dash::Html::Components::Template->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Template->new(@_);
}

sub Textarea {
    shift @_;
    load Dash::Html::Components::Textarea;
    if ( Dash::Html::Components::Textarea->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Textarea->new(@_);
}

sub Tfoot {
    shift @_;
    load Dash::Html::Components::Tfoot;
    if ( Dash::Html::Components::Tfoot->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Tfoot->new(@_);
}

sub Th {
    shift @_;
    load Dash::Html::Components::Th;
    if ( Dash::Html::Components::Th->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Th->new(@_);
}

sub Thead {
    shift @_;
    load Dash::Html::Components::Thead;
    if ( Dash::Html::Components::Thead->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Thead->new(@_);
}

sub Time {
    shift @_;
    load Dash::Html::Components::Time;
    if ( Dash::Html::Components::Time->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Time->new(@_);
}

sub Title {
    shift @_;
    load Dash::Html::Components::Title;
    if ( Dash::Html::Components::Title->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Title->new(@_);
}

sub Tr {
    shift @_;
    load Dash::Html::Components::Tr;
    if ( Dash::Html::Components::Tr->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Tr->new(@_);
}

sub Track {
    shift @_;
    load Dash::Html::Components::Track;
    if ( Dash::Html::Components::Track->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Track->new(@_);
}

sub U {
    shift @_;
    load Dash::Html::Components::U;
    if ( Dash::Html::Components::U->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::U->new(@_);
}

sub Ul {
    shift @_;
    load Dash::Html::Components::Ul;
    if ( Dash::Html::Components::Ul->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Ul->new(@_);
}

sub Var {
    shift @_;
    load Dash::Html::Components::Var;
    if ( Dash::Html::Components::Var->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Var->new(@_);
}

sub Video {
    shift @_;
    load Dash::Html::Components::Video;
    if ( Dash::Html::Components::Video->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Video->new(@_);
}

sub Wbr {
    shift @_;
    load Dash::Html::Components::Wbr;
    if ( Dash::Html::Components::Wbr->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Wbr->new(@_);
}

sub Xmp {
    shift @_;
    load Dash::Html::Components::Xmp;
    if ( Dash::Html::Components::Xmp->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Html::Components::Xmp->new(@_);
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Html::Components

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
