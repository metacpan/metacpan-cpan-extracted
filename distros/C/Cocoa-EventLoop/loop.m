#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

// undefine Move macro, this is conflict to Mac OS X QuickDraw API.
#undef Move

#import <Foundation/Foundation.h>

@interface Cocoa__EventLoop__Timer : NSObject {
@public
    NSTimer* timer;
    SV* cb;
}
-(void)callback;
@end

@implementation Cocoa__EventLoop__Timer

-(void)callback {
    dSP;

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

-(void)dealloc {
    [super dealloc];
}

@end

@protocol NSStreamDelegate;

@interface Cocoa__EventLoop__IOWatcher : NSObject <NSStreamDelegate> {
@public
    int fd;
    int mode;
    NSInputStream* read_stream;
    NSOutputStream* write_stream;
    SV* rcb;
    SV* wcb;
}
-(void)setup_watcher;
-(void)reset_watcher;
@end

@implementation Cocoa__EventLoop__IOWatcher

-(void)setup_watcher {
    read_stream = nil;
    write_stream = nil;

    CFStreamCreatePairWithSocket(
        kCFAllocatorDefault, fd,
        NULL != rcb ? &read_stream : NULL,
        NULL != wcb ? &write_stream : NULL
    );

    if (NULL != rcb) {
        [read_stream setDelegate:self];
        [read_stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];
        [[read_stream retain] open];
    }

    if (NULL != wcb) {
        [write_stream setDelegate:self];
        [write_stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
        [[write_stream retain] open];
    }
}

-(void)reset_watcher {
    if (nil != read_stream) {
        [read_stream close];
        [read_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];
        [read_stream release];
        read_stream = nil;
    }

    if (nil != write_stream) {
        [write_stream close];
        [write_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
        [write_stream release];
        write_stream = nil;
    }

    [self setup_watcher];
};

-(void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    SV* cb = NULL;

    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            cb = wcb;
            break;
        case NSStreamEventHasBytesAvailable:
            cb = rcb;
            break;
        default:
            //NSLog(@"ignore event: %d", eventCode);
            return;
    }

    if (NULL == cb) return;
    [self reset_watcher];

    // callback
    dSP;

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

@end

XS(run_while) {
    dXSARGS;

    if (items < 2) {
        Perl_croak(aTHX_ "usage: Cocoa::EventLoop->run_while($secs)\n");
    }

    SV* sv_secs = ST(1);
    if (!SvOK(sv_secs) || !SvNIOK(sv_secs)) {
        Perl_croak(aTHX_ "usage: run_while($secs)\n");
    }

    double secs = SvNV(sv_secs);

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:secs]];
    [pool drain];

    XSRETURN(0);
}

XS(run) {
    dXSARGS;

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [[NSRunLoop currentRunLoop] run];
    [pool drain];

    XSRETURN(0);
}

XS(add_timer) {
    dXSARGS;

    if (items < 4) {
        Perl_croak(aTHX_ "Usage: add_timer($obj, $after, $interval, $cb)");
    }

    SV* sv_obj      = ST(0);
    SV* sv_after    = ST(1);
    SV* sv_interval = ST(2);
    SV* sv_cb       = ST(3);

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    double after    = SvNV(sv_after);
    double interval = SvNV(sv_interval);

    Cocoa__EventLoop__Timer* t = [[Cocoa__EventLoop__Timer alloc] init];

    t->cb = SvREFCNT_inc(sv_cb);
    t->timer = [[NSTimer alloc]
                   initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:after]
                           interval:interval
                             target:t
                           selector:@selector(callback)
                           userInfo:nil
                            repeats:interval ? YES : NO];

    sv_magic(SvRV(sv_obj), NULL, PERL_MAGIC_ext, NULL, 0);
    mg_find(SvRV(sv_obj), PERL_MAGIC_ext)->mg_obj = (void*)t;

    [[NSRunLoop currentRunLoop] addTimer:t->timer
                                 forMode:NSDefaultRunLoopMode];

    [pool drain];

    XSRETURN(0);
}

XS(remove_timer) {
    dXSARGS;

    if (items < 1) {
        Perl_croak(aTHX_ "Usage: remove_timer($timer)");
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    SV* sv_timer = ST(0);

    MAGIC* m = mg_find(SvRV(sv_timer), PERL_MAGIC_ext);
    Cocoa__EventLoop__Timer* t = (Cocoa__EventLoop__Timer*)m->mg_obj;

    [t->timer invalidate];
    SvREFCNT_dec(t->cb);
    [t release];

    [pool drain];

    XSRETURN(0);
}

XS(add_io) {
    dXSARGS;

    if (items < 4) {
        Perl_croak(aTHX_ "Usage: add_io($obj, $fd, $mode, $cb)");
    }

    SV* sv_obj  = ST(0);
    SV* sv_fd   = ST(1);
    SV* sv_mode = ST(2);
    SV* sv_cb   = ST(3);

    int fd   = SvIV(sv_fd);
    int mode = SvIV(sv_mode);

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    MAGIC* m = mg_find(SvRV(sv_obj), PERL_MAGIC_ext);
    if (m) {
        Cocoa__EventLoop__IOWatcher* io = (Cocoa__EventLoop__IOWatcher*)m->mg_obj;
        if (mode == 0) { // read
            if (io->rcb) SvREFCNT_dec(io->rcb);
            io->rcb = SvREFCNT_inc(sv_cb);
        }
        else {
            if (io->wcb) SvREFCNT_dec(io->wcb);
            io->wcb = SvREFCNT_inc(sv_cb);
        }
        [io reset_watcher];
    }
    else {
        Cocoa__EventLoop__IOWatcher* io = [[Cocoa__EventLoop__IOWatcher alloc] init];
        io->fd = fd;
        if (mode == 0) { // read
            io->rcb = SvREFCNT_inc(sv_cb);
            io->wcb = NULL;
        }
        else {
            io->rcb = NULL;
            io->wcb = SvREFCNT_inc(sv_cb);
        }
        [io setup_watcher];

        sv_magic(SvRV(sv_obj), NULL, PERL_MAGIC_ext, NULL, 0);
        mg_find(SvRV(sv_obj), PERL_MAGIC_ext)->mg_obj = (void*)io;
    }

    [pool drain];

    ST(0) = sv_obj;
    XSRETURN(1);
}

XS(remove_io) {
    dXSARGS;

    if (items < 2) {
        Perl_croak(aTHX_ "Usage: remove_io($obj, $mode)");
    }

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    SV* sv_obj = ST(0);
    SV* sv_mode = ST(1);

    int mode = SvIV(sv_mode);
    int flag = 0;

    MAGIC* m = mg_find(SvRV(sv_obj), PERL_MAGIC_ext);
    if (m) {
        Cocoa__EventLoop__IOWatcher* io = (Cocoa__EventLoop__IOWatcher*)m->mg_obj;

        if (0 == mode && NULL != io->rcb) { // read
            SvREFCNT_dec(io->rcb);
            io->rcb = NULL;
        }
        if (1 == mode && NULL != io->wcb) {
            SvREFCNT_dec(io->wcb);
            io->wcb = NULL;
        }

        if (NULL == io->rcb && NULL == io->wcb) {
            flag = io->fd;

            [io->read_stream close];
            [io->read_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                       forMode:NSDefaultRunLoopMode];
            [io->write_stream close];
            [io->write_stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                        forMode:NSDefaultRunLoopMode];
            [io->read_stream release];
            [io->write_stream release];
            [io release];
        }
    }

    [pool release];

    SV* ret = sv_2mortal(newSViv(flag));
    ST(0) = ret;
    XSRETURN(1);
}

XS(boot_Cocoa__EventLoop) {
    newXS("Cocoa::EventLoop::run_while", run_while, __FILE__);
    newXS("Cocoa::EventLoop::run", run, __FILE__);
    newXS("Cocoa::EventLoop::__add_timer", add_timer, __FILE__);
    newXS("Cocoa::EventLoop::__remove_timer", remove_timer, __FILE__);
    newXS("Cocoa::EventLoop::__add_io", add_io, __FILE__);
    newXS("Cocoa::EventLoop::__remove_io", remove_io, __FILE__);
}
