# Attribute::RecordCallers

A Perl module to keep a record of who called a subroutine, from
where, and when.

A few lines of example: (see the module documentation for more)

    use Attribute::RecordCallers;
    sub call_me_and_i_ll_tell_you : RecordCallers { ... }
    ...
    END {
        use Data::Dumper;
        print Dumper \%Attribute::RecordCallers::callers;
    }
