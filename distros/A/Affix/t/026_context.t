use v5.40;
use Test2::V0;
use Affix qw[:all];
use Affix::Build;
#
my $c = Affix::Build->new();
$c->add( \<<~'END', lang => 'c' );
    typedef void SV;

    // Callback: SV* tick(SV* context)
    // Returns: NULL (Done) or SV* (Next Step CodeRef)
    typedef SV* (*tick_cb_t)(SV*, SV*);

    typedef struct {
        SV* context; // Perl HashRef
        SV* current_step; // Perl CodeRef
    } Actor;

    static Actor g_actor;

    void spawn(SV* ctx, SV* first_step) {
        g_actor.context = ctx;
        g_actor.current_step = first_step;
    }

    void run_scheduler(tick_cb_t wrapper) {
        // Run limited steps to prevent infinite loop if logic fails
        int max_steps = 10;
        while (g_actor.current_step && max_steps-- > 0) {
            // Call Perl wrapper. It executes the current step and returns the next one.
            g_actor.current_step = wrapper(g_actor.current_step, g_actor.context);
        }
    }
    END
ok my $lib = $c->link, 'Compiled C scheduler lib';
#
typedef SVPtr   => Pointer [SV];
typedef Wrapper => Callback [ [ SVPtr(), SVPtr() ] => SVPtr() ];
affix $lib, 'spawn',         [ SVPtr(), SVPtr() ] => Void;
affix $lib, 'run_scheduler', [ Wrapper() ]        => Void;
#
my $wrapper = sub ( $code_ref, $ctx_ref ) {

    # Convert void* back to Perl CodeRef
    # Affix should now automatically unwrap the SV* from the Pointer[SV]
    return $code_ref->($ctx_ref);
};

# Define Linear Logic
my $step3 = sub ($ctx) {
    $ctx->{count}++;
    pass 'Step 3 executed';
    undef;    # Finish
};
my $step2 = sub ($ctx) {
    $ctx->{count}++;
    pass 'Step 2 executed';
    $step3;
};
my $step1 = sub ($ctx) {
    $ctx->{count} = 1;
    pass 'Step 1 executed';
    $step2;
};
#
my $context = { id => 1, count => 0 };

# This verifies that spawn correctly accepts Perl SVs as "SVPtr" (aliased Pointer[SV])
spawn( $context, $step1 );

# This verifies that run_scheduler correctly calls the callback,
# and the callback correctly receives SVs back from C.
run_scheduler($wrapper);
#
is $context->{count}, 3, 'All steps executed and context updated';
#
done_testing();
