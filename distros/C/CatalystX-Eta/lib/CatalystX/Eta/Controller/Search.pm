package CatalystX::Eta::Controller::Search;

use Moose::Role;
use Moose::Util::TypeConstraints;

requires 'list_GET';

around list_GET => \&Search_arround_list_GET;

sub Search_arround_list_GET {
    my $orig = shift;
    my $self = shift;

    my ($c) = @_;

    my %may_search;

    if ( exists $self->config->{search_ok} ) {
        foreach my $key_ok ( keys %{ $self->config->{search_ok} } ) {
            if ( exists $c->req->params->{$key_ok} ) {
                $may_search{$key_ok} = $c->req->params->{$key_ok};

            }
            elsif ( exists $c->req->params->{"$key_ok:IN"} ) {

                push @{ $may_search{$key_ok}{'-or'} }, [ split /\n/, $c->req->params->{"$key_ok:IN"} ];

            }
            else {
                my $type = $self->config->{search_ok}{$key_ok};

                for my $exp ( qw|< > >= <= +< +> +>= +<=|, ( $type eq 'Str' ? qw/like ilike/ : () ) ) {

                    if ( exists $c->req->params->{"$key_ok:$exp"} ) {
                        my $tmp = "$exp";    # not more read only
                        $tmp =~ s/^(\+)?//;
                        my $gp = $1 && $1 eq '+' ? '-and' : '-or';
                        push @{ $may_search{$key_ok}{$gp} }, { $tmp => $c->req->params->{"$key_ok:$exp"} };
                    }
                }
            }
        }
    }

    foreach my $key ( keys %may_search ) {

        my $type = $self->config->{search_ok}{$key};
        my $val  = $may_search{$key};

        $may_search{$key} = undef, next
          if ( ( $type eq 'Bool' || $type eq 'Int' || $type eq 'Num' || ref $type eq 'MooseX::Types::TypeDecorator' )
            && $val eq '' );

        my $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint($type);

        $self->status_bad_request( $c, message => "Unknown type constraint '$type'" ), $c->detach
          unless defined($cons);

        if ( ref $val eq 'HASH' ) {

            # many groups
            foreach my $gp ( keys %$val ) {

                foreach my $a_val ( @{ $val->{$gp} } ) {
                    my $checkval = ref $a_val eq 'HASH' ? $a_val->{ ( keys %$a_val )[0] } : $a_val;

                    if ( !$cons->check($checkval) ) {
                        $self->status_bad_request( $c, message => "invalid param $key for $checkval" );
                        $c->detach;
                    }
                }
            }

            # such valided

        }
        else {
            my $checkval = $val;
            if ( !$cons->check($checkval) ) {

                $self->status_bad_request( $c, message => "invalid param $key" ), $c->detach;
            }
        }
    }

    my $base = $self->config->{search_base} || 'me';
    foreach my $k ( keys %may_search ) {
        my $on_table = $k !~ /\./ ? "$base.$k" : "$k";

        my $such_val = delete $may_search{$k};

        if ( ref $such_val eq 'HASH' ) {
            for my $op ( keys %$such_val ) {
                push @{ $may_search{$op} }, map { +{ $on_table => $_ } } @{ $such_val->{$op} };
            }
        }
        else {
            $may_search{$on_table} = $such_val;
        }

    }

    $c->stash->{collection} = $c->stash->{collection}->search( {%may_search} )
      if %may_search;

    if ( exists $c->req->params->{limit_rows} && $c->req->params->{limit_rows} =~ /^[0-9]+$/ ) {
        $c->stash->{collection} = $c->stash->{collection}->search(
            undef,
            {
                rows => $c->req->params->{limit_rows}
            }
        );
    }

    $self->$orig(@_);
}

1;

