package CLI::Driver::ArgParserRole;

use Modern::Perl;
use Moose::Role;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

#########################################################################################

#########################################################################################

=pod orig

method _parse_req_args (HashRef :$type_href) {

    my @ret;

    foreach my $subtype ( keys %$type_href ) {

        my $hard;
        if ( $subtype eq 'hard' ) {
            $hard = 1;
        }
        elsif ( $subtype eq 'soft' ) {
            $hard = 0;
        }
        else {
            $self->warn("unrecognized required arg subtype: $subtype");
        }

        my $subtype_href = $type_href->{$subtype};

        foreach my $cli_arg ( keys %$subtype_href ) {

            my $method_arg = $subtype_href->{$cli_arg};
            my $opt        = CLI::Driver::Option->new(
                required   => 1,
                hard       => $hard,
                cli_arg    => $cli_arg,
                method_arg => $method_arg
            );

            push @ret, $opt;
        }
    }

    return @ret;
}

=cut

# synonym for _parse_req_args
method _parse_req_attrs (HashRef :$type_href) {

    return $self->_parse_req_args(@_);
}

method _parse_req_args (HashRef :$type_href) {

    my @ret;

    foreach my $cli_arg ( keys %$type_href ) {

        if ( $cli_arg eq 'hard' or $cli_arg eq 'soft' ) {
            push @ret,
              $self->_parse_req_args_v1(
                type_href => $type_href,
                subtype   => $cli_arg
              );
        }
        else {
            push @ret,
              $self->_parse_req_args_v2(
                type_href => $type_href,
                cli_arg   => $cli_arg
              );
        }
    }

    return @ret;
}

method _parse_req_args_v2 (HashRef :$type_href!, 
                           Str     :$cli_arg! ) {
    
    my $method_arg = $type_href->{$cli_arg};
    
    my $is_array = 0;
    if( $method_arg =~ s/^\@(.+)/$1/ ){
        $is_array = 1;
    }
        
    return CLI::Driver::Option->new(
        required   => 1,
        hard       => 1,
        cli_arg    => $cli_arg,
        method_arg => $method_arg,
        is_array   => $is_array,
        use_argv_map => $self->use_argv_map ? 1 : 0
    );
}

method _parse_req_args_v1 (HashRef :$type_href!, 
                           Str     :$subtype! ) {

    my @ret;

    my $hard;
    if ( $subtype eq 'hard' ) {
        $hard = 1;
    }
    elsif ( $subtype eq 'soft' ) {
        $hard = 0;
    }
    else {
        $self->warn("unrecognized required arg subtype: $subtype");
    }

    my $subtype_href = $type_href->{$subtype};

    foreach my $cli_arg ( keys %$subtype_href ) {
        
        my $method_arg = $subtype_href->{$cli_arg};
        
        my $is_array = 0;
        if( $method_arg =~ s/^\@(.+)$/$1/ ){
            $is_array = 1;
        }

        push @ret,
          CLI::Driver::Option->new(
            required   => 1,
            hard       => $hard,
            cli_arg    => $cli_arg,
            method_arg => $method_arg,
            is_array   => $is_array,
            use_argv_map => $self->use_argv_map ? 1 : 0
          );
    }

    return @ret;
}

# alias for _parse_opt_args
method _parse_opt_attrs (HashRef :$type_href) {

    return $self->_parse_opt_args(@_);
}

method _parse_opt_args (HashRef :$type_href) {

    my @ret;
    
    foreach my $cli_arg ( keys %$type_href ) {

        my $method_arg = $type_href->{$cli_arg};
        
        my $is_array = 0;
        if( $method_arg =~ s/^\@(.+)$/$1/ ){
            $is_array = 1;
        }

        my $opt = CLI::Driver::Option->new(
            required   => 0,
            cli_arg    => $cli_arg,
            method_arg => $method_arg,
            is_array   => $is_array,
            use_argv_map => $self->use_argv_map ? 1 : 0
        );
        
        push @ret, $opt;
    }

    return @ret;
}

# alias for _parse_flag_args
method _parse_flag_attrs (HashRef :$type_href) {

    return $self->_parse_flag_args(@_);
}

method _parse_flag_args (HashRef :$type_href) {

    my @ret;

    foreach my $cli_arg ( keys %$type_href ) {

        my $method_arg = $type_href->{$cli_arg};

        my $opt = CLI::Driver::Option->new(
            required   => 0,
            cli_arg    => $cli_arg,
            method_arg => $method_arg,
            flag       => 1,
            use_argv_map => $self->use_argv_map ? 1 : 0,
        );

        push @ret, $opt;
    }

    return @ret;
}

method _parse_attrs (HashRef :$href!) {

    my $attr_href = defined $href->{attr} ? $href->{attr} : {};
    return $self->__parse_args( args_href => $attr_href );
}

method _parse_args (HashRef :$href!) {

    my $args_href = defined $href->{args} ? $href->{args} : {};
    return $self->__parse_args( args_href => $args_href );
}

method __parse_args (HashRef :$args_href!) {

    my @args;
    
    foreach my $type ( keys %$args_href ) {

        my $type_href = $args_href->{$type};
        
        if ( defined $type_href ) {
            if ( $type =~ /^opt/ ) {
                my @opt = $self->_parse_opt_args( type_href => $type_href );
                push @args, @opt;
            }
            elsif ( $type =~ /^req/ ) {
                my @req = $self->_parse_req_args( type_href => $type_href );
                push @args, @req;
            }
            elsif ( $type =~ /^flag/ ) {
                my @flag = $self->_parse_flag_args( type_href => $type_href );
                push @args, @flag;
            }
            else {
                $self->warn("unrecognized type: $type");
            }
        }
    }
    
    return \@args;
}

1;

