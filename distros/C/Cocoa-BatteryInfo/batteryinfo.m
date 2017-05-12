#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

// undefine Move macro, this is conflict to Mac OS X QuickDraw API.
#undef Move

#import <Foundation/Foundation.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>

#include <notify.h>
#include <string.h>

static inline SV* nsnumber_to_sv(NSNumber* n) {
    SV* sv;

    switch (*[n objCType]) {
        case 'c':
            // char
            sv = newSViv([n charValue]);
            break;
        case 'i':
            // int
            sv = newSViv([n intValue]);
            break;
        case 's':
            // short
            sv = newSViv([n shortValue]);
            break;
        case 'l':
            // long
            sv = newSViv([n longValue]);
            break;
        case 'q':
            // long long
            sv = newSViv([n longLongValue]);
            break;
        case 'C':
            // unsigned char
            sv = newSVuv([n unsignedCharValue]);
            break;
        case 'I':
            // unsigned int
            sv = newSVuv([n unsignedIntValue]);
            break;
        case 'S':
            // unsigned short
            sv = newSVuv([n unsignedShortValue]);
            break;
        case 'L':
            // unsigned long
            sv = newSVuv([n unsignedLongValue]);
            break;
        case 'Q':
            // unsigned long long
            sv = newSVuv([n unsignedLongLongValue]);
            break;
        case 'f':
            // float
            sv = newSVnv([n floatValue]);
            break;
        case 'd':
            // double
            sv = newSVnv([n doubleValue]);
            break;
        case 'B':
            // bool
            sv = newSViv([n boolValue]);
            break;
        default:
            sv = NULL;
    }

    return sv;
}

XS(XS_Cocoa__BatteryInfo_info) {
    dXSARGS;
    CFTypeRef si;
    int i;
    SV* sv_source = NULL;
    char* source = NULL;
    STRLEN len;
    HV* hv;
    SV** unused;
    SV* res = NULL;

    if (items >= 2) {
        sv_source = ST(1);
        source = SvPV(sv_source, len);
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    si = IOPSCopyPowerSourcesInfo();
    if (!si) {
        [pool drain];
        Perl_croak(aTHX_ "IOPSCopyPowerSourcesInfo failed");
    }

    NSArray* sources = (NSArray*)IOPSCopyPowerSourcesList(si);
    if (!sources) {
        CFRelease(si);
        [pool drain];
        Perl_croak(aTHX_ "IOPSCopyPowerSourcesList failed");
    }

    for (i = 0; i < [sources count]; i++) {
        CFTypeRef ps = (CFTypeRef)[sources objectAtIndex:i];
        NSDictionary* info = (NSDictionary*)IOPSGetPowerSourceDescription(si, ps);

        if (NULL != source) {
            NSString* nameKey = [NSString stringWithUTF8String:kIOPSNameKey];
            NSString* name    = [info objectForKey:nameKey];
            if (nil == name) continue;

            if (0 != strcmp([name UTF8String], source))
                continue;
        }

        hv = (HV*)sv_2mortal((SV*)newHV());

        NSArray* keys = [info allKeys];
        for (NSString* key in keys) {
            NSObject* v = [info objectForKey:key];

            if ([v isKindOfClass:[NSString class]]) {
                unused = hv_store(hv,
                    [key UTF8String], [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                    newSVpvn([(NSString*)v UTF8String],
                        [(NSString*)v lengthOfBytesUsingEncoding:NSUTF8StringEncoding]), 0);
            }
            else if ([v isKindOfClass:[NSNumber class]]) {
                SV* sv_v = nsnumber_to_sv((NSNumber*)v);
                if (NULL == sv_v) continue;

                unused = hv_store(hv,
                    [key UTF8String], [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                    sv_v, 0);
            }
        }

        res = sv_2mortal(newRV_inc((SV*)hv));

        break;
    }

    CFRelease((CFArrayRef)sources);
    CFRelease(si);

    [pool drain];

    if (NULL != res) {
        ST(0) = res;
        XSRETURN(1);
    }
    else {
        XSRETURN(0);
    }
}

XS(XS_Cocoa__BatteryInfo_sources) {
    dXSARGS;
    CFTypeRef si;
    int i, count;
    SV* sv;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    si = IOPSCopyPowerSourcesInfo();
    if (!si) {
        [pool drain];
        Perl_croak(aTHX_ "IOPSCopyPowerSourcesInfo failed");
    }

    NSArray* sources = (NSArray*)IOPSCopyPowerSourcesList(si);
    if (!sources) {
        CFRelease(si);
        [pool drain];
        Perl_croak(aTHX_ "IOPSCopyPowerSourcesList failed");
    }

    NSString* nameKey = [NSString stringWithUTF8String:kIOPSNameKey];
    count = 0;
    for (i = 0; i < [sources count]; i++) {
        CFTypeRef ps = (CFTypeRef)[sources objectAtIndex:i];
        NSDictionary* info = (NSDictionary*)IOPSGetPowerSourceDescription(si, ps);

        NSString* name = [info objectForKey:nameKey];
        if (nil == name) continue;

        sv = sv_2mortal(newSVpvn([name UTF8String],
                [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding]));
        ST(count++) = sv;
    }

    CFRelease((CFArrayRef)sources);
    CFRelease(si);

    [pool drain];

    XSRETURN(count);
}

XS(XS_Cocoa__BatteryInfo_time_remaining_estimate) {
    dXSARGS;
    SV* sv;
    CFTimeInterval t;

    t = IOPSGetTimeRemainingEstimate();

    if (kIOPSTimeRemainingUnlimited == t) {
        sv = newSVpvn("unlimited", 9);
    }
    else if (kIOPSTimeRemainingUnknown == t) {
        sv = newSVpvn("unknown", 7);
    }
    else {
        sv = newSVnv(t);
    }

    ST(0) = sv_2mortal(sv);
    XSRETURN(1);
}

XS(XS_Cocoa__BatteryInfo_battery_warning_level) {
    dXSARGS;
    SV* sv;
    IOPSLowBatteryWarningLevel level;

    level = IOPSGetBatteryWarningLevel();
    sv = newSViv(level);

    ST(0) = sv_2mortal(sv);
    XSRETURN(1);
}

XS(XS_Cocoa__BatteryInfo_low_battery_handler) {
    dXSARGS;
    SV* sv_handler;
    int status, token;

    if (items != 1) {
        Perl_croak(aTHX_ "Usage: Cocoa::BatteryInfo::low_battery_handler(CodeRef)");
    }

    sv_handler = get_sv("Cocoa::BatteryInfo::_low_battery_handler", GV_ADD);
    sv_setsv(sv_handler, ST(0));

    status = notify_register_dispatch(
        kIOPSNotifyLowBattery, &token,
        dispatch_get_main_queue(), ^(int t) {
            dSP;

            SV* cb = get_sv("Cocoa::BatteryInfo::_low_battery_handler", 0);
            if (cb) {
                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                PUTBACK;

                call_sv(cb, G_SCALAR);

                SPAGAIN;

                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
    );

    XSRETURN(0);
}

XS(XS_Cocoa__BatteryInfo_time_remaining_handler) {
    dXSARGS;
    SV* sv_handler;
    int status, token;

    if (items != 1) {
        Perl_croak(aTHX_ "Usage: Cocoa::BatteryInfo::time_remaining_estimate(CodeRef)");
    }

    sv_handler = get_sv("Cocoa::BatteryInfo::_time_remaining_handler", GV_ADD);
    sv_setsv(sv_handler, ST(0));

    status = notify_register_dispatch(
        kIOPSTimeRemainingNotificationKey, &token,
        dispatch_get_main_queue(), ^(int t) {
            dSP;

            SV* cb = get_sv("Cocoa::BatteryInfo::_time_remaining_handler", 0);
            if (cb) {
                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                PUTBACK;

                call_sv(cb, G_SCALAR);

                SPAGAIN;

                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
    );

    XSRETURN(0);
}

XS(boot_Cocoa__BatteryInfo) {
    newXS("Cocoa::BatteryInfo::info", XS_Cocoa__BatteryInfo_info, __FILE__);
    newXS("Cocoa::BatteryInfo::sources", XS_Cocoa__BatteryInfo_sources, __FILE__);
    newXS("Cocoa::BatteryInfo::time_remaining_estimate", XS_Cocoa__BatteryInfo_time_remaining_estimate, __FILE__);
    newXS("Cocoa::BatteryInfo::battery_warning_level", XS_Cocoa__BatteryInfo_battery_warning_level, __FILE__);

/* NOTE: the prototype of newXSproto() is different in versions of perls,
 * so we define a portable version of newXSproto()
 */
#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
#else
#define newXSproto_portable(name, c_impl, file, proto) (PL_Sv=(SV*)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV*)PL_Sv)
#endif /* !defined(newXS_flags) */

    newXSproto_portable("Cocoa::BatteryInfo::low_battery_handler", XS_Cocoa__BatteryInfo_low_battery_handler, __FILE__, "&");
    newXSproto_portable("Cocoa::BatteryInfo::time_remaining_handler", XS_Cocoa__BatteryInfo_time_remaining_handler, __FILE__, "&");
}
