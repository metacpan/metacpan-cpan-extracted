package Catalyst::Plugin::FormValidator::Lazy ;

use strict;
use warnings;
use NEXT;
use UNIVERSAL::require;
use Data::FormValidator;

our $VERSION = '0.05';

#{{{ setup
sub setup {
    my $c = shift;

    my $conf = $c->config->{form_validator_lazy};
    my $pkg = $conf->{method_pkg} ;
    $pkg->require or die $@;

    $conf->{_strict}
        = _make_constraints( $pkg , $conf->{strict} , 'strict' );

    $conf->{_loose}
        = _make_constraints( $pkg , $conf->{loose} , 'loose' );

    $conf->{_regexp}
        = _make_constraint_regexp_map( $pkg , $conf->{regexp_map} );

    $c->NEXT::setup( @_ );

    return $c;
}
#}}}


#{{{ has_dfv_error
sub has_dfv_error {
    my $c = shift;

    if ( $c->form->has_invalid or $c->form->has_missing or exists $c->stash->{custom_invalid} ) {
        return 1;
    }
    else {
        return 0;
    }
}
#}}}

sub prepare {
    my $c = shift;
    $c = $c->NEXT::prepare(@_);
    $c->{form} = Data::FormValidator->check( $c->request->parameters, {} );
    return $c;
}

#{{{ form 
sub form {
    my $c = shift;
    if ( $_[0] ) {
        my $form = $_[1] ? {@_} : $_[0];
        my $conf = $c->config->{form_validator_lazy};
        my $custom_parameters = undef;

        if ( !$form->{constraints} ) {
            my %constraints = %{ $conf->{_strict} };
            $form->{constraints} = \%constraints;

            if ( $form->{constraints_loose} ) {
                for my $key ( @{ $form->{constraints_loose} } ) {
                    $form->{constraints}{ $key } = $c->config->{_loose}{ $key };
                }
                delete $form->{constraints_loose};
            }

        }
        if( !$form->{constraint_regexp_map} ) {
            $form->{constraint_regexp_map} = $conf->{_regexp} ;
        }

        if( $form->{custom_parameters} ) {
            $custom_parameters = $form->{custom_parameters} ;
            delete $form->{custom_parameters} ;
        }

        $c->{form} =
          Data::FormValidator->check( $custom_parameters || $c->request->parameters , $form );

        $c->stash->{v} = $c->{form}{valid} ;
        for my $key ( $c->{form}->invalid  ) {
            $c->stash->{invalid}{ $key } = 1;
        }

        for my $key ( $c->{form}->missing  ) {
            $c->stash->{missing}{ $key } = 1;
        }
    }
    return $c->{form};
}
#}}}

#{{{ dfv_push_invalid
sub dfv_push_invalid {
    my $c   = shift;
    my $key = shift;
   
    if ( ref $key eq 'ARRAY') {
        $c->stash->{custom_invalid} = {};
        &_array2hashkey( $c->stash->{custom_invalid} , $key , 1 );
    }
    else {
        $c->stash->{custom_invalid}{ $key } = 1;
    }

}
#}}}

#{{{ _array2hashkey
sub _array2hashkey {
    my $hash  = shift;
    my $keys  = shift;
    my $value = shift;

    return if !scalar @{ $keys };

    my $key = shift @{$keys};
    $hash->{$key} = scalar @{ $keys } ? {} : $value;
    _array2hashkey( $hash->{$key} , $keys , $value ) ;
}
#}}}

#{{{ _make_constraint_regexp_map
sub _make_constraint_regexp_map {
    my $pkg  = shift;
    my $data = shift;
    my $constraints = {};
    foreach my $key ( keys %{ $data } ) {
             my $value = $data->{ $key } ;
             if( ref $value eq 'ARRAY' ) {
                my $method = $value->[0]; 
                my @args = @{ $value };
                shift @args;
                my $sub =  $pkg . '::' . 'static' .  '_' .  $method  ;
                $constraints->{ qr/$key/ } 
                    = sub { 
                        my $item = shift ; 
                        no strict;
                        my $result =  $sub->( $item  ,@args );
                        return $result;
                      }
                    ;
             }
             else {
                $constraints->{ qr/$key/ } = qr/$value/;
             }
    }

    return $constraints;
}
#}}}

#{{{ _make_constraints
sub _make_constraints {
    my $pkg  = shift;
    my $data = shift;
    my $mode = shift;

    my $constraints = {};

    foreach my $key ( keys %{ $data } ) {
        my $value = $data->{ $key };

        if ( $value eq 'method' ) {
            local *glob =  $pkg . '::' . $mode .  '_' .  $key;
            $constraints->{ $key } = \&glob ;
        }
        elsif ( ref $value eq 'ARRAY' ) {
            my $method = $value->[0]; 
            my @args = @{ $value };
            shift @args;
            my $sub =  $pkg . '::' . 'static' .  '_' .  $method  ;
            $constraints->{ $key } 
                = sub { 
                    my $item = shift ; 
                    no strict;
                    my $result =  $sub->( $item  ,@args );
                    return $result;
                  }
                ;
        }
        else {
             $constraints->{ $key } = qr/$value/;
        }
    }
    return $constraints;
}
#}}}

1;

=head1 NAME

Catalyst::Plugin::FormValidator::Lazy - Catalyst FormValidator Plugin in Lazy way 

=head1 DESCRIPTION

Instead of writting constraints in your controller source code , this plugin let you
use config file. and more...

=head1 SYNOPSYS

 use Catalyst qw( FormValidator::Lazy ); 
 
 sub foo : Local {
    my ( $s , $c ) = @_;
    $c->form(
        required            => [qw/user_name password monster/],
        constraints_loose   => [qw/user_name/],
        custom_parameters   => {
                                    user_name => 'tomyhero',
                                    password  => 'hi_mom', 
                                    monster   => 'doragon',
                                },
     );
     
     return if $c->has_dfv_error ;

    # do something!
 }
 
foo.tt

    <td><input type="text" name="user_name"></td>
    <td>&nbsp;[% IF invalid.user_name %]User Name Is Invalid [% END -%][% IF missing.user_name %]User Name is Missing [% END -%] </td>

app.yml

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'
    regexp_map : 
        '_id$' : '^\d+$'
        '_cd$' : 
            - string
    strict     :
        user_name : method
        password  : '^[a-zA-Z0-9]+$'
        doragon   : 
            - string
            - 10 
   loose       :
        user_name : method
        password  : '.+'

TestApp/Constraints.pm

 Package TestApp::Constraints;

 sub strict_user_name {
    my $value = shift;
    return $value eq 'tomyhero' ? 1 : 0 ;
 }

 sub loose_user_name {
    my $value = shift;
    return 1 ;
 }

 sub static_string {
    my $value  = shift;
    my $length = shift;

    return length $value <= $length ? 1 : 0 ; 
 }

 1;

=head1 LAZY WAY

=head2 I want to forget about constraints. 

I am not a smart person who can think about many thing together. When I
codeing controller I evern not want to think about constraints. I want
to write constraints when I finish everything or when I finish design DB
layout or whatever when I feel I want to work on constraints staff. 

that is why this plugin use config file to solve this problem.

app.yml

 form_validator_lazy :
    strict     :
        user_name : '^[a-zA-Z0-9]+$' 
        password  : '^[a-zA-Z0-9]+$'

in your controller.

    # even no constraints here , do not worry , it is ready!
    $c->form(
        required => [qw/user_name password/],
    );

=head2 I do not want config data is complicated.

I like simple. When I think about too much I always get headache.
I did not want to set constraints per controller like bellow.

 controller_name_a:
    user_name : '^[a-zA-Z0-9]+$'
    password  : '^[a-zA-Z0-9]+$'
 controlller_name_b: 
    user_name : '^[a-zA-Z0-9]+$'
    password  : '^[a-zA-Z0-9]+$'

When I design  a system , I named request parameter very carefully so
that a parameter never contain different kind of validation . I mean below
situation never happen. 

 # some case this
 user_name => qr/^[a-zA-Z]+$/;
 # other case this
 user_name => qr/^[a-zA-Z0-9]+$/;

But I realize some case we need to have 2 kind of validation for a key. like
fazzy search...

 form_validator_lazy :
    strict     :
        user_name : qr/^[a-zA-Z]+$/
    loose      :
        user_name : qr/^[a-zA-Z%]+$/

that is why you can set strict and loose for your config file.  strict is
default. When you want to use loose constraints then,

 $c->form(
    required => [qw/user_name/],
    constraints_loose => [qw/user_name/],
 );

easy??

=head2 I want to use method for constraints!!!

Yeah , even I am lazy to create methods for constraints , I need them.. 
We need to set which package containt the methods

using config file.

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'

How to write??

    package TestApp::Constraints;
    
    sub strict_user_name {
        my $user_name = shift;
    
        return $user_name eq 'tomyhero' ? 1 : 0 ;
    }
    
    sub loose_user_name {
        my $user_name = shift;
        return $user_name =~ /^tom/ ? 1 : 0 ;
    }

    1;

how to use it??
the keyword 'method' automatically read method from package. and the method
name is ${prefix}_${parameter_key_name} . 

app.yml

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'
    strict :
        user_name : method # TestApp::Constraints::strict_user_name
    loose  :
        user_name : method # TestApp::Constraints::loose_user_name
   
easy?

=head2 Oh.. I do not want same function but different name 

If I follow strict_ and loose_ methods rule then I will end up writng like
below methods.

    package TestApp::Constraints;
    
    sub strict_user_id {
        my $id = shift;
        return $id =~ /^\d+$/ ? 1 : 0 ;
    }

    sub strict_goods_id {
        my $id = shift;
        return $id =~ /^\d+$/ ? 1 : 0 ;
    }

app.yml

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'
    strict :
        user_id : method 
        goods_id: method


I hate this. So that I add static_ prefix method...
how to use it??

 app.yml

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'
    strict :
        user_id : 
            - number
        goods_id:
            - number


    package TestApp::Constraints;
    
    sub static_number {
        my $id = shift;
        return $id =~ /^\d+$/ ? 1 : 0 ;
    }

Now , not really great but I think it OK.

I forget to tell , static_ method can have arg(s). 

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'
    strict :
        user_id : 
            - number 
            - 10
        goods_id:
            - number
            - 3


    package TestApp::Constraints;
    
    sub static_number {
        my $id     = shift;
        my $length = shift;
        return 0 of length $id > $length ; 
        return $id =~ /^\d+$/ ? 1 : 0 ;
    }

I think this is nice. 

=head2 I even do not want to type parameter at config.

Yeah , I am lazy to type even parameter key...

app.yml

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'
    strict :
        user_id  : '^\d+$' 
        member_id: '^\d+$'
        person_id: '^\d+$'
        human_id : '^\d+$'

like this situation you can do like this. So you can save even typeing parameters!

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'
    regexp_map     :
        '_id$' : '^\d+$'

=head2 I am lazy to use two methods for error checking.

Instead of this

    if ( $c->form->has_invalid or $c->form->has_missing ) {
        $c->detach('hi_mom');
    }

use this.

    if( $c->has_dfv_error ) {
        $c->detach('hi_mom');
    }

=head2 I want to customaize parameters!!! 

you can use custom_parameters hash key!

    # get parameters from custom_parameters instead of $c->request->parameters
    # Of course you do not need to set if you do not use it. this is option. 
    $c->form(
        custom_parameters => { user_name => 'tomohiro' , password => 'hi_mom' },
        required => [qw/user_name password/],
    );

=head2 I am lazy to retrive invalid or missing error key from array in some case.

Desiners want to set error message at specific postision sometimes. 
And also your validated data is ready to use at $c->stash->{v}

app.yml

 form_validator_lazy :
    method_pkg : 'TestApp::Constraints'

foo.tt

 <td><input type="text" name="user_name"></td>
 <td>&nbsp;[% IF invalid.user_name %]User Name Is Invalid [% END -%][% IF missing.user_name %]User Name is Missing [% END -%] </td>

=head2 I want to add custom errors.

Yes you can.

 $c->dfv_push_invalid( 'key_name' );

or 

 $c->dfv_push_invalid( ['key1' , 'key2'] );

and after this , $c->has_dfv_error will return 1 and also set 

 $c->stash->{custom_error}{key_name} = 1;
 $c->stash->{custom_error}{key1}{key2} = 1,

=head1 METHOD

=head2 form

Returns a L<Data::FormValidator::Results> object.

=head2 has_dfv_error

Having invalid or missing error or not.

=head2 dfv_push_invalid

You can add your custom error with this module.

=head1 SEE ALSO

L<Data::FormValidator>

=head1 AUTHOR

Tomohiro Teranishi C<tomohiro.teranishi@gmail.com>

=cut

