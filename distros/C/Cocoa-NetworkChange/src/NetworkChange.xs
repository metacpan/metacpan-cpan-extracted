#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_newSVpvn_flags
#include "ppport.h"

#undef Move

#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLAN.h>

#import "Reachability.h"

static inline SV*
nsstring_to_sv(NSString* str) {
    SV* sv = sv_2mortal(newSV(0));
    sv_setpv(sv, [str UTF8String]);
    return sv;
}

static void
set_current_interface(CWInterface* interface, HV* hv_interface) {
    (void)hv_store(hv_interface, "ssid", 4,
        SvREFCNT_inc(nsstring_to_sv([interface ssid])), 0);
    (void)hv_store(hv_interface, "interface", 9,
        SvREFCNT_inc(nsstring_to_sv([interface interfaceName])), 0);
    (void)hv_store(hv_interface, "mac_address", 11,
        SvREFCNT_inc(nsstring_to_sv([interface hardwareAddress])), 0);
    (void)hv_store(hv_interface, "bssid", 5,
        SvREFCNT_inc(nsstring_to_sv([interface bssid])), 0);
}

MODULE = Cocoa::NetworkChange    PACKAGE = Cocoa::NetworkChange

PROTOTYPES: DISABLE

void
on_network_change(SV* sv_connect_cb, ...)
PPCODE:
{
    SV* connect_cb = get_sv("Cocoa::NetworkChange::__connect_cb", GV_ADD);
    sv_setsv(connect_cb, sv_connect_cb);

    if (items > 1) {
        SV* disconnect_cb = get_sv("Cocoa::NetworkChange::__disconnect_cb", GV_ADD);
        sv_setsv(disconnect_cb, ST(1));
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    Reachability* reach = [Reachability reachabilityForInternetConnection];
    reach.reachableBlock = ^(Reachability* reach){
        dispatch_sync(dispatch_get_main_queue(), ^{
            CWInterface* currentInterface = [CWInterface interfaceWithName:nil];
            HV* hv_interface = (HV*)sv_2mortal((SV*)newHV());
            set_current_interface(currentInterface, hv_interface);

            SV* connect_cb = get_sv("Cocoa::NetworkChange::__connect_cb", 0);
            if (connect_cb) {
                dSP;
                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newRV_inc((SV*)hv_interface)));
                PUTBACK;

                call_sv(connect_cb, G_SCALAR);

                SPAGAIN;

                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        });
    };
    reach.unreachableBlock = ^(Reachability* reach){
        dispatch_sync(dispatch_get_main_queue(), ^{
            SV* disconnect_cb = get_sv("Cocoa::NetworkChange::__disconnect_cb", 0);
            if (disconnect_cb) {
                dSP;
                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                PUTBACK;

                call_sv(disconnect_cb, G_SCALAR);

                SPAGAIN;

                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        });
    };

    [reach startNotifier];

    [pool drain];
}

int
is_network_connected()
CODE:
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    Reachability* reach = [Reachability reachabilityForInternetConnection];

    if ([reach isReachable]) {
        RETVAL = 1;
    } else {
        RETVAL = 0;
    }

    [pool drain];
}
OUTPUT:
    RETVAL

SV*
current_interface()
CODE:
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    CWInterface* currentInterface = [CWInterface interfaceWithName:nil];
    HV* hv_interface = (HV*)sv_2mortal((SV*)newHV());
    set_current_interface(currentInterface, hv_interface);

    [pool drain];

    ST(0) = sv_2mortal(newRV_inc((SV*)hv_interface));
    XSRETURN(1);
}
