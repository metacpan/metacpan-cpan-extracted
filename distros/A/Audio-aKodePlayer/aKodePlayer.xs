#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#include <akode/player.h>
#include <akode/decoder.h>
#include <akode/sink.h>
#include <akode/resampler.h>
#include <akode/pluginhandler.h>
#include <string>
#include <list>

#define aKode__Player aKode::Player /* should fix a xsubpp related problem */


MODULE = Audio::aKodePlayer           PACKAGE = Audio::aKodePlayer

aKode::Player *
aKode::Player::new ()

bool
aKode::Player::open (sinkname)
    const char* sinkname

void
aKode::Player::DESTROY ()

void 
aKode::Player::close ()

bool
aKode::Player::load (filename)
    const char* filename

void
aKode::Player::setDecoderPlugin (plugin)
    const char * plugin

void
aKode::Player::setResamplerPlugin (plugin)
    const char * plugin

void
aKode::Player::unload ()

void
aKode::Player::play ()

void
aKode::Player::stop ()

void
aKode::Player::wait ()

void
aKode::Player::detach ()

void
aKode::Player::pause ()

void
aKode::Player::resume ()

void
aKode::Player::setVolume (volume)
    float volume

float
aKode::Player::volume ()
    
int
aKode::Player::state  ()

bool
aKode::Player::seek(milliseconds)
    long milliseconds
    CODE:
        aKode::Decoder* decoder = THIS->decoder();
        if (! decoder )
            XSRETURN_UNDEF;
        else
            RETVAL = decoder->seek(milliseconds);
    OUTPUT:
        RETVAL

long
aKode::Player::length ()
    CODE:
        aKode::Decoder* decoder = THIS->decoder();
        if (! decoder )
            XSRETURN_UNDEF;
        else
            RETVAL = decoder->length(); 
    OUTPUT:
        RETVAL

long
aKode::Player::position ()
    CODE:
        aKode::Decoder* decoder = THIS->decoder();
        if (! decoder )
            XSRETURN_UNDEF;
        else
            RETVAL = decoder->position(); 
    OUTPUT:
        RETVAL

bool
aKode::Player::seekable ()
    CODE:
        aKode::Decoder* decoder = THIS->decoder();
        if (! decoder )
            XSRETURN_UNDEF;
        else
            RETVAL = decoder->seekable(); 
    OUTPUT:
        RETVAL

bool
aKode::Player::eof ()
    CODE:
        aKode::Decoder* decoder = THIS->decoder();
        if (! decoder )
            XSRETURN_UNDEF;
        else
            RETVAL = decoder->eof(); 
    OUTPUT:
        RETVAL

bool
aKode::Player::decoderError ()
    CODE:
        aKode::Decoder* decoder = THIS->decoder();
        if (! decoder )
            XSRETURN_UNDEF;
        else
            RETVAL = decoder->error(); 
    OUTPUT:
        RETVAL

void
aKode::Player::setSampleRate (rate)
      unsigned int rate
    CODE:
        aKode::Resampler* resampler = THIS->resampler();
        if ( resampler )
            resampler->setSampleRate(rate);

void
aKode::Player::setSpeed (value)
      float value
    CODE:
        aKode::Resampler* resampler = THIS->resampler();
        if ( resampler )
            resampler->setSpeed(value); 

void
listPlugins ()
    INIT:
        std::list<std::string> lst;
    PPCODE:
	lst = aKode::PluginHandler::listPlugins();
	EXTEND(SP,lst.size());
        for (std::list<std::string>::const_iterator i=lst.begin(), e=lst.end(); i!=e; ++i) {
	  XPUSHs(sv_2mortal(newSVpv(i->c_str(),i->length())));
        }

void 
listSinks ()
    INIT:
        std::list<std::string> lst;
    PPCODE:
        lst = aKode::SinkPluginHandler::listSinkPlugins();
	EXTEND(SP,lst.size());
        for (std::list<std::string>::const_iterator i=lst.begin(), e=lst.end(); i!=e; ++i) {
	  XPUSHs(sv_2mortal(newSVpv(i->c_str(),i->length())));
        }

void 
listDecoders ()
    INIT:
        std::list<std::string> lst;
    PPCODE:
        lst = aKode::DecoderPluginHandler::listDecoderPlugins();
	EXTEND(SP,lst.size());
        for (std::list<std::string>::const_iterator i=lst.begin(), e=lst.end(); i!=e; ++i) {
	  XPUSHs(sv_2mortal(newSVpv(i->c_str(),i->length())));
        }
