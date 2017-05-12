package Test::ActiveMQ;

use Moose;
use Data::Serializer;
use MooseX::Types::Moose qw/Str/;
use MooseX::Types -declare => [qw/Dir Serializer/];
use Moose::Util::TypeConstraints;


use Path::Class qw/dir/;

use Test::Builder;
use Test::More;
use Test::Differences qw/eq_or_diff/;
use Test::Deep::NoTest qw/eq_deeply/;
use Devel::PartialDump;

extends 'Moose::Object', 'Test::Builder::Module';

class_type 'Path::Class::Dir';
subtype Dir, as 'Path::Class::Dir';
coerce Dir, from 'Str',
    via { dir($_) };

has dump_dir => (
    is          => 'ro',
    isa         => Dir,
    required    => 1,
    default     => undef,
    coerce      => 1,
);


class_type 'Data::Serializer';
subtype Serializer, as 'Data::Serializer';
coerce Serializer, from 'Str',
    via { Data::Serializer->new( serializer => $_ ) };

has serializer => (
    is          => 'ro',
    isa         => Serializer,
    required    => 1,
    default     => 'JSON',
    coerce      => 1,

);



sub message_matches {
    my ($self, $opts, $comment) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $queue = $opts->{queue} || confess "No queue specified!";

    my ($predicate, $data) = @$opts{qw/predicate compare_with/};


    $predicate = { body => $predicate } unless exists $predicate->{body};
    $data = { body => $data } unless exists $data->{body};
    use Data::Dump qw/pp/;

    my @messages = $self->_messages("/queue/$queue");

    unless (@messages) {
        $self->builder->ok(0, $comment);
        $self->builder->diag("No ActiveMQ messages found on $queue");
        return 0;
    }

#    $predicate = $self->preprocess_data($predicate);
    #my $full_want = $self->preprocess_data($data);
    my $full_want = $data; #$self->preprocess_data($data);

    for my $msg_file (@messages) {
        my $payload = $self->_load_message($msg_file);

        next unless Data::Overlay::overlay($payload, $predicate);

        # So the predicate matched, not see if the payload matches.
        if ( Data::Overlay::overlay($payload, $full_want) ) {
            $self->builder->ok(1, $comment);
            return 1;
        }
        # overlay didn't match! give a eq_or_diff which should give a useful-ish output
        $self->builder->diag("\n*\n* Please Note:\n*   The diff below is not sensible.\n*   The RHS column is just the overlay\n*\n");
        return eq_or_diff($payload, $full_want, $comment);
    }
    $self->builder->ok(0, $comment);
    # 
    my $dumper = Devel::PartialDump->new(max_depth => 5);
    $self->builder->diag("No ActiveMQ messages found matching " . $dumper->dump($predicate));
    return 0;
}

sub _load_message {
    my ($self, $file) = @_;

    my $data = $file->slurp;

    my $msg = $self->serializer->raw_deserialize( $data );
    # body is a JSON *string* - turn it into a perl hash
    $msg->{body} = $self->serializer->raw_deserialize($msg->{body});
    return $msg;
}



sub to_json {
    my ($self, $body) = @_;

    return $self->serializer->raw_serialize($body);

}

sub _messages {
    my($self, $queue) = @_;

    $queue =~ s{^/}{};
    $queue =~ s{/}{_}g;
     my $dir = $self->dump_dir;

     my @kids = sort { $b->basename cmp $a->basename }
#               grep { $_->basename =~ /\Q$queue\E/ }
               grep { !$_->is_dir } $dir->children;

    return @kids;
}


# Data::Overlay from Konobi
package Data::Overlay;

use strict;
use warnings;
use Scalar::Util qw(reftype);

sub overlay {
    my ($data, $overlay) = @_;

    my $level = 0;

    if(reftype($overlay) eq 'HASH'){
        return overlay_hash($data, $overlay, $level+2);
    } elsif(reftype($overlay) eq 'ARRAY'){
        return overlay_array($data, $overlay, $level+2);
    } else {
        return ($data eq $overlay) ? 1 : 0;
    }

}

sub overlay_hash {
    my ($data, $overlay, $level) = @_;

    for my $k (keys %$overlay){
        my $overlay_item = $overlay->{$k};
        my $reftype = reftype($overlay_item) || '';

        if ($reftype eq 'SCALAR' && $$overlay_item eq 'Missing') {
            # foo => \'Missing' says we *want* this value to not be present in
            # $data
            return 0 if exists $data->{$k};
        } elsif ($reftype eq 'CODE') {
            # foo => sub { return 1 if ($_[0]); return 0 }  says we have code to decide
            # if its good or bad
            return &{$overlay_item}($data->{$k});
        } else {
            return 0 if !exists $data->{$k};
        }
        my $data_item = $data->{$k};

        if( !ref($overlay_item) ){
            return 0 if !($data_item eq $overlay_item);
            next;
        }

        if(reftype($overlay_item) eq 'HASH'){
            return 0 if !overlay_hash($data_item, $overlay_item, $level+2);
        } elsif (reftype($overlay_item) eq 'ARRAY'){
            return 0 if !overlay_array($data_item, $overlay_item, $level+2);
        }
    }

    return 1;
}

sub overlay_array {
    my ($data, $overlay, $level) = @_;

    # Go through each item in the overlay and compare against each element of
    # the data
    my $all_items_found = 1;
    for my $item (@$overlay){
        my $overlay_item_found = 0;

        INT: for my $data_entry (@$data){
            if(!ref($item)){
                $overlay_item_found = ($item eq $data_entry) ? 1 : 0;
            } elsif(reftype($item) eq 'HASH'){
                $overlay_item_found = overlay_hash($data_entry, $item, $level+2);
            } elsif(reftype($item) eq 'ARRAY'){
                $overlay_item_found = overlay_array($data_entry, $item, $level+2);
            }
            last INT if $overlay_item_found;
        }

        # if we currently think all items up to now are found then we
        if($all_items_found){
            $all_items_found = $overlay_item_found ? 1 : 0;
        }

        if(!$all_items_found){
            last;
        }
    }

    return $all_items_found;
}


1;
