#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

// undefine Move macro, this is conflict to Mac OS X QuickDraw API.
#undef Move

#import <Foundation/Foundation.h>
#ifdef USE_LOCAL_GROWL
#import <Growl/Growl.h>
#else
#import <Growl.h>
#endif
#import <objc/runtime.h>

static Class GrowlAppBridge;

@interface GrowlContext : NSObject {
@public
    SV* timeout_cb;
    SV* click_cb;
}
@end

@implementation GrowlContext
-(void)dealloc {
    if (NULL != timeout_cb) SvREFCNT_dec(timeout_cb);
    if (NULL != click_cb) SvREFCNT_dec(click_cb);
    [super dealloc];
}
@end

@interface Growl : NSObject <GrowlApplicationBridgeDelegate> {
    NSDictionary* info_;
    NSMutableDictionary* contexts_;
}
+(Growl*)sharedInstance;
-(NSDictionary*)info;
-(void)setInfo:(NSDictionary*)newInfo;
-(NSString*)addContext:(GrowlContext*)context;
-(void)removeContext:(NSString*)key;
@end

@implementation Growl

+(Growl*)sharedInstance {
    static Growl* obj = nil;
    if (nil == obj) {
        obj = [[Growl alloc] init];
    }
    return obj;
}

-(id)init {
    if (self = [super init]) {
        info_ = nil;
        contexts_ = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

-(NSDictionary*)info {
    return info_;
}

-(void)setInfo:(NSDictionary*)newInfo {
    if (nil != info_) {
        [info_ release];
    }
    info_ = [newInfo retain];
}

-(NSString*)addContext:(GrowlContext*)context {
    // create dic key
    CFUUIDRef uuid_ref = CFUUIDCreate(nil);
    NSString* uuid = (NSString*)CFUUIDCreateString(nil, uuid_ref);
    CFRelease(uuid_ref);

    [contexts_ setObject:context forKey:uuid];

    return [uuid autorelease];
}

-(void)removeContext:(NSString*)key {
    [contexts_ removeObjectForKey:key];
}

-(NSDictionary*)registrationDictionaryForGrowl {
    return info_;
}

-(void)growlNotificationWasClicked:(id)clickContext {
    GrowlContext* context = [contexts_ objectForKey:(NSString*)clickContext];
    if (context && context->click_cb) {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        PUTBACK;

        call_sv(context->click_cb, G_SCALAR);

        SPAGAIN;

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    [self removeContext:clickContext];
    [context release];
}

-(void)growlNotificationTimedOut:(id)clickContext {
    GrowlContext* context = [contexts_ objectForKey:(NSString*)clickContext];
    if (context && context->timeout_cb) {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        PUTBACK;

        call_sv(context->timeout_cb, G_SCALAR);

        SPAGAIN;

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    [self removeContext:clickContext];
    [context release];
}

-(void)dealloc {
    [info_ release];
    [contexts_ release];
    [super dealloc];
}

@end

XS(growl_installed) {
    dXSARGS;

    SV* sv;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if ([GrowlAppBridge isGrowlInstalled]) {
        sv = newSViv(1);
    }
    else {
        sv = newSViv(0);
    }
    [pool drain];

    ST(0) = sv_2mortal(sv);

    XSRETURN(1);
}

XS(growl_running) {
    dXSARGS;

    SV* sv;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if ([GrowlAppBridge isGrowlRunning]) {
        sv = newSViv(1);
    }
    else {
        sv = newSViv(0);
    }
    [pool drain];

    ST(0) = sv_2mortal(sv);

    XSRETURN(1);
}

XS(growl_register) {
    dXSARGS;

    if (items < 3) {
        Perl_croak(aTHX_ "Usage: _growl_register($app_name, \\@allNotifications, \\@defaultNotifications[, $iconFile])");
    }

    SV* sv_appName = ST(0);
    SV* sv_allNotif = ST(1);
    SV* sv_defaultNotif = ST(2);
    SV* sv_image = NULL;
    if (items >= 4) sv_image = ST(3);

    if (!SvROK(sv_allNotif) || !SvROK(sv_defaultNotif) ||
        SVt_PVAV != SvTYPE(SvRV(sv_allNotif)) ||
        SVt_PVAV != SvTYPE(SvRV(sv_defaultNotif))) {

        Perl_croak(aTHX_ "Error: \\@allNotifications and \\@defaultNotifications should be ArrayRef");
    }

    STRLEN len;
    char* ptr;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    ptr = SvPV(sv_appName, len);
    NSString* appName = [NSString stringWithUTF8String:ptr];

    NSData* icon = nil;
    if (sv_image && SvOK(sv_image)) {
        ptr = SvPV(sv_image, len);
        NSString* iconFile = [NSString stringWithUTF8String:ptr];
        NSURL* url = [NSURL URLWithString:iconFile];
        icon = [NSData dataWithContentsOfURL:url];
    }

    SV** svp;
    AV* av;
    int i, alen;

    NSMutableArray* all = [NSMutableArray array];
    av     = (AV*)SvRV(sv_allNotif);
    alen = av_len(av) + 1;
    for (i = 0; i < alen; ++i) {
        svp = av_fetch(av, i, 0);
        if (svp) {
            ptr = SvPV(*svp, len);
            [all addObject:[NSString stringWithUTF8String:ptr]];
        }
    }

    NSMutableArray* defaults = [NSMutableArray array];
    av     = (AV*)SvRV(sv_defaultNotif);
    alen = av_len(av) + 1;
    for (i = 0; i < alen; ++i) {
        svp = av_fetch(av, i, 0);
        if (svp) {
            ptr = SvPV(*svp, len);
            [defaults addObject:[NSString stringWithUTF8String:ptr]];
        }
    }

    NSDictionary* info;
    if (icon) {
        info = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:1],     GROWL_TICKET_VERSION,
                                            @"org.unknownplace.cocoagrowl", GROWL_APP_ID,
                                            appName,                        GROWL_APP_NAME,
                                            all,                            GROWL_NOTIFICATIONS_ALL,
                                            defaults,                       GROWL_NOTIFICATIONS_DEFAULT,
                                            icon,                           GROWL_APP_ICON,
                                       nil];
    }
    else {
        info = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:1],     GROWL_TICKET_VERSION,
                                            @"org.unknownplace.cocoagrowl", GROWL_APP_ID,
                                            appName,                        GROWL_APP_NAME,
                                            all,                            GROWL_NOTIFICATIONS_ALL,
                                            defaults,                       GROWL_NOTIFICATIONS_DEFAULT,
                                       nil];
    }

    [[Growl sharedInstance] setInfo:info];

    [pool drain];

    XSRETURN(0);
}

XS(growl_notify) {
    dXSARGS;

    if (items < 3) {
        Perl_croak(aTHX_ "Usage: _growl_notify($title, $description, $name[, $icon, $click_callback, $timeout_callback, $sticky, $priority])");
    }

    SV* sv_title = ST(0);
    SV* sv_desc  = ST(1);
    SV* sv_name  = ST(2);

    SV* sv_icon = NULL;
    if (items >= 4 && SvOK(ST(3))) sv_icon = ST(3);

    SV* sv_click_callback = NULL;
    SV* sv_timeout_callback = NULL;
    if (items >= 5 && SvOK(ST(4))) sv_click_callback = ST(4);
    if (items >= 6 && SvOK(ST(5))) sv_timeout_callback = ST(5);

    SV* sv_sticky = NULL;
    if (items >= 7 && SvOK(ST(6))) sv_sticky = ST(6);

    SV* sv_priority = NULL;
    if (items >= 8 && SvOK(ST(7))) sv_priority = ST(7);

    STRLEN len;
    char* s;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    s = SvPV(sv_title, len);
    NSString* title = [NSString stringWithUTF8String:s];

    s = SvPV(sv_desc, len);
    NSString* description = [NSString stringWithUTF8String:s];

    s = SvPV(sv_name, len);
    NSString* name = [NSString stringWithUTF8String:s];

    [GrowlAppBridge setGrowlDelegate:[Growl sharedInstance]];

    NSString* context_key = nil;
    if (sv_click_callback || sv_timeout_callback) {
        GrowlContext* context = [[GrowlContext alloc] init];
        context->click_cb = sv_click_callback;
        context->timeout_cb = sv_timeout_callback;

        if (sv_click_callback) SvREFCNT_inc(sv_click_callback);
        if (sv_timeout_callback) SvREFCNT_inc(sv_timeout_callback);

        context_key = [[Growl sharedInstance] addContext:context];
    }

    NSData* icon = nil;
    if (sv_icon && SvOK(sv_icon)) {
        s = SvPV(sv_icon, len);
        NSString* iconFile = [NSString stringWithUTF8String:s];
        NSURL* url = [NSURL URLWithString:iconFile];
        icon = [NSData dataWithContentsOfURL:url];
    }

    BOOL sticky = NO;
    if (sv_sticky && SvIV(sv_sticky)) sticky = YES;

    int priority = 0;
    if (sv_priority) priority = SvIV(sv_priority);

    [GrowlAppBridge notifyWithTitle:title
                        description:description
                   notificationName:name
                           iconData:icon
                           priority:priority
                           isSticky:sticky
                       clickContext:context_key];

    [pool drain];

    XSRETURN(0);
}

XS(boot_Cocoa__Growl) {
    SV* dir = get_sv("Cocoa::Growl::FRAMEWORK_DIR", FALSE);

    STRLEN len;
    char* d = SvPV(dir, len);

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    GrowlAppBridge = objc_getClass("GrowlApplicationBridge");
    if (!GrowlAppBridge) {
        NSBundle* growl = [NSBundle bundleWithPath:[NSString stringWithUTF8String:d]];
        NSError* err = nil;
        if (growl && [growl loadAndReturnError:&err]) {
            //NSLog(@"growl load success");
            GrowlAppBridge = objc_getClass("GrowlApplicationBridge");
        }
        else {
            if (nil != err) {
                Perl_croak(aTHX_ "Coudn't load Growl framework: %s\n",
                    [[err localizedDescription] UTF8String]);
            }
            else {
                Perl_croak(aTHX_ "Coudn't initialize Growl bundle\n");
            }
        }
    }

    [pool drain];

    newXS("Cocoa::Growl::growl_installed", growl_installed, __FILE__);
    newXS("Cocoa::Growl::growl_running", growl_running, __FILE__);
    newXS("Cocoa::Growl::_growl_register", growl_register, __FILE__);
    newXS("Cocoa::Growl::_growl_notify", growl_notify, __FILE__);
}
