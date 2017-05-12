use MooseX::Declare;

role CatalystX::Declare::Context::StringParsing {

    use Devel::Declare;

    method rest_of_line {

        $self->skipspace;

        my $linestr = $self->get_linestr;
        my $left    = substr $linestr, $self->offset;

        return $left;
    }

    method strip_from_linestr (Int $chars) {

        my $linestr = $self->get_linestr;
        substr($linestr, $self->offset, $chars) = '';
        $self->set_linestr($linestr);
    }

    method get_string {

        my $left = $self->rest_of_line;

        # only work on allowed types of string declarations
        if ($left =~ /^"/ and my $num = Devel::Declare::toke_scan_str $self->offset) {

            my $found = Devel::Declare::get_lex_stuff;
            Devel::Declare::clear_lex_stuff;
            
            $self->strip_from_linestr($num);
            
            return qq{"$found"};
        }

        # check for a scalar version if nothing found
        else {
            return $self->get_scalar;
        }
    }

    method get_scalar {
        
        my $left = $self->rest_of_line;

        # only allow simple scalars
        if ($left =~ s/^ ( \$ [a-z_] [a-z0-9_]* ) //ix) {

            my $found = $1;

            $self->strip_from_linestr( length $found );

            return qq{"$found"};
        }

        # nothing suitable found
        else {
            return undef;
        }
    }
}
