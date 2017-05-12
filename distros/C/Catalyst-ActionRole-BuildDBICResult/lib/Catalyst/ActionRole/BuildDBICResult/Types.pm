package ## No PAUSE index
  Catalyst::ActionRole::BuildDBICResult::Types;

use strict;
use warnings;

use Perl6::Junction qw(any all);
use MooseX::Types::Moose qw(HashRef ArrayRef Object CodeRef Str Bool);
use MooseX::Types -declare => [qw(
    StoreType 
    FindCondition 
    FindConditions 
    HandlerActionInfo 
    Handlers
    AutoStash
)];

subtype StoreType,
    as HashRef,
    where {
        my ($store_type, @extra) = keys %$_;
        my $return;
        unless(@extra) {
            if($store_type eq any(qw/model accessor stash value code/)) {
                $return = 1;
            } else {
                $return = 0;
            }
        } else {
            $return = 0;
        }
        $return;
    };

coerce StoreType,
    from Object,
    via { +{value => $_} },
    from CodeRef,
    via { +{code => $_} },
    from Str,
    via { 
        my $type = $_;
        my $return;
        if(
            ($type=~m/::/) ||
            ($type=~m/^[A-Z]/)
        ) {
            $return = {model => $type};
        } else {
            $return = {stash => "$type"};
        }
        $return;
    };

subtype FindCondition,
    as HashRef,
    where {
        my @keys = keys(%$_);
        my $return;
        if(
            (any(@keys) eq any(qw/constraint_name columns/)) and
            (all(@keys) eq any(qw/constraint_name match_order columns/))
        ) {
            if($_->{columns} and ref $_->{columns}) {
                $return = ref $_->{columns} eq 'ARRAY' ? 1 : 0;
            } else {
                $return = 1;
            }
        } else {
            $return = 0;
        }
        $return;
    };

coerce FindCondition,
    from Str,
    via { +{constraint_name=>$_} },
    from ArrayRef,
    via { +{columns=>$_} };

subtype FindConditions,
    as ArrayRef[FindCondition];

coerce FindConditions,
    from FindCondition,
    via { +[$_] },
    from Str,
    via { +[{constraint_name=>$_}] },
    from ArrayRef,
    via {
        [map { to_FindCondition($_) } @$_];
    };

subtype HandlerActionInfo,
    as HashRef,
    where {
        my @keys = keys(%$_);
        if(
            ($#keys == 0) and
            (all(@keys) eq any(qw/forward detach visit go/))
        ) {
            1;
        } else {
            0;
        }
    },
    message { "Disallowed Key in: ". join(',', keys(%$_)) };

subtype Handlers,
    as HashRef[HandlerActionInfo],
    where {
        my @keys = keys(%$_);
        if(all(@keys) eq any(qw/found notfound error/)) {
            1;
        } else {
            0;
        }
    },
    message { "Disallowed key in: ". join(',',keys(%$_)) };

coerce Handlers,
    from HashRef[Str],
    via { 
        my ($type,$target) = %$_;
        +{$type => {detach=>$target}};
     };

subtype AutoStash,
    as Bool|Str;
1;

=head1 NAME

Catalyst::ActionRole::BuildDBICResult::Types - A type library class

=head1 SYNOPSIS

    use Catalyst::ActionRole::BuildDBICResult::Types qw(Handlers);

=head1 DESCRIPTION

A L<MooseX::Types> based type constraint library for use in
L<Catalyst::ActionRole::BuildDBICResult>

You probably don't need to use these, they are primarily for internal use.

=head1 AUTHOR

John Napiorkowski <jjnapiork@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2010, John Napiorkowski <jjnapiork@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

