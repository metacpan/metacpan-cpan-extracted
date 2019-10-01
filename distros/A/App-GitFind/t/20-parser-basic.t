#use Sub::Multi::Tiny::Util qw(*VERBOSE);
#BEGIN { $VERBOSE = 99; $Data::Dumper::Indent = 1;}
#BEGIN { $App::GitFind::cmdline::SHOW_AST = 1; }

use strict;
use warnings;
use lib::relative '.';
use TestKit;

#use Data::Dumper::Compact 0.004001 qw(ddc);  # DEBUG

use App::GitFind::cmdline;
my $p = \&App::GitFind::cmdline::Parse;

# Permit extra fields so I don't have to add 'index'
# and 'code' to each R() parameter.

{
    package main::_build_R_checker;
    use Sub::Multi::Tiny qw(D:TypeParams $spec);
    use Test2::V0;
    use Types::Standard qw(Ref ArrayRef HashRef);

    sub _array :M(ArrayRef $spec) {
        return array {
            foreach my $v (@$spec) {
                item _build_R_checker($v);
            }
            etc();
        };
    }

    sub _hash :M(HashRef $spec) {
        return hash {
            while(my ($k, $v) = each(%$spec)) {
                field $k => _build_R_checker($v);
            }
            etc();
        };
    }

    sub _other_ref :M(Ref $spec) {
        die "I don't know how to handle reftype @{[ref $spec]}";
    }

    sub _scalar :M($spec) {
        return $spec;
    }
} #_build_R_checker()

# Build a record we can test against.  This is to make the list of tests
# more readable.
sub R {
    my ($saw_npa, $saw_nrr, $saw_rr, %rest) = @_;
    my $retval = _build_R_checker(+{
        saw_nonprune_action => $saw_npa,
        saw_non_rr => $saw_nrr,
        saw_rr => $saw_rr,
        %rest
    });
    #diag 'R: ' . ddc $retval;
    return $retval;
} #R()

my $ok=List::AutoNumbered->new(__LINE__);
$ok->load([qw(-u)], R(false, false, false, switches=>{u=>[true]}))->    # switch
    ([qw(master)], R(false, true, false, revs=>['master']))             # ref
    ([qw(-empty)], R(false, false, false, expr=>{name=>'empty'}))       # test
    ([qw(-print)], R(true, false, false, expr=>{name=>'print'}))        # action
    ([qw(-u master)], R(false, true, false, switches=>{u=>[true]}))   # switch + ref
    # switch + ref + test
    (LSKIP 1, [qw(-u master -empty)], R(false, true, false, switches=>{u=>[true]}, revs=>['master'], expr=>{name=>'empty'}))
    ([qw(-u master -print)], R(true, true, false, switches=>{u=>[true]}, revs=>['master'], expr=>{name=>'print'}))
    # switch + ref + test + action
    (LSKIP 1, [qw(-u master -empty -print)], R(true, true, false, switches=>{u=>[true]}, revs=>['master'], expr=>{AND=>[{name=>'empty'}, {name=>'print'}]}))
    # Then the same, but with --
    (LSKIP 1, [qw(-u --)], R(false, false, false, switches=>{u=>[true]}))   # switch

    # switch + ref + action
    (LSKIP 2, [qw(master --)], R(false, true, false, revs=>['master'])) # ref
    ([qw(-- -empty)], R(false, false, false, expr=>{name=>'empty'}))    # test
    ([qw(-- -print)], R(true, false, false, expr=>{name=>'print'}))     # action
    # switch + ref
    (LSKIP 1, [qw(-u master --)], R(false, true, false, switches=>{u=>[true]}, revs=>['master']))
    # switch + ref + test
    (LSKIP 1, [qw(-u master -- -empty)], R(false, true, false, switches=>{u=>[true]}, revs=>['master'], expr=>{name=>'empty'}))
    # switch + ref + action
    (LSKIP 1, [qw(-u master -- -print)], R(true, true, false, switches=>{u=>[true]}, revs=>['master'], expr=>{name=>'print'}))
    # switch + ref + test + action
    (LSKIP 1, [qw(-u master -- -empty -print)], R(true, true, false, switches=>{u=>[true]}, revs=>['master'], expr=>{AND=>[{name=>'empty'}, {name=>'print'}]}))
    ;

# More complicated tests
$ok->load(LSKIP 3, [qw(-empty -o -readable -true)], R(false, false, false, expr=>{OR=>[{name=>'empty'}, {AND=>[{name=>'readable'},{name=>'true'}]}]}))->
    (['-executable', ',', '-readable'], R(false, false, false, expr=>{SEQ=>[{name=>'executable'}, {name=>'readable'}]}))
    (['-executable', ',', '-readable', '-empty'], R(false, false, false, expr=>{SEQ=>[{name=>'executable'},{AND=>[{name=>'readable'},{name=>'empty'}]}]}))
    ;

foreach(@{$ok->arr}) {
    my $lineno = $$_[0];
    my $lrArgs = $$_[1];
    my $name = "line $$_[0]: [" . join(' : ', @$lrArgs) . ']';
    #diag "======================================\nTrying $name";
    my $ast = $p->($lrArgs);    # add ,0x1f for full debug output
    is $ast, $$_[2], $name;
    #diag "GOT ", ddc $ast;
    #diag "WANT ", ddc $$_[2];
}

done_testing();
