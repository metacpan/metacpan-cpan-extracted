#ifndef __PERLCONTACTLISTENER_H__
#define __PERLCONTACTLISTENER_H__

#include <Box2D/Box2D.h>
#include <helper.h>

class PerlContactListener : public b2ContactListener
{
  public:
  SV * beginContact;
  SV * endContact;
  SV * preSolve;
  SV * postSolve;
  
  PerlContactListener( ):
    beginContact(NULL),
    endContact(NULL),
    preSolve(NULL),
    postSolve(NULL) {}
  
    ~PerlContactListener(){};
  
  void SetBeginContactSub( void * ourSub ) {
    /* Take a copy of the callback */
      if (beginContact == NULL) {
        /* First time, so create a new SV */
        /* fprintf(stderr,"Setting BeginContact!\n"); */
        beginContact = newSVsv( (SV*)ourSub ) ;
      } else {
        /* Been here before, so overwrite */
        SvSetSV(beginContact,  (SV*)ourSub ) ;
      }
  }
  void SetEndContactSub( void * s) {
    /* Take a copy of the callback */
      if (endContact == (SV*)NULL)
        /* First time, so create a new SV */
        endContact = newSVsv( (SV*) s) ;
      else
        /* Been here before, so overwrite */
        SvSetSV(endContact, (SV*) s) ;
  }
  void SetPreSolveSub( void * s ) {
    /* Take a copy of the callback */
      if (preSolve == (SV*)NULL)
        /* First time, so create a new SV */
        preSolve = newSVsv( (SV*)s) ;
      else
        /* Been here before, so overwrite */
        SvSetSV(preSolve, (SV*)s) ;
  }
  void SetPostSolveSub( void * s) {

      if (postSolve == (SV*)NULL)
        /* First time, so create a new SV */
        postSolve = newSVsv((SV*)s) ;
      else
        /* Been here before, so overwrite */
        SvSetSV(postSolve, (SV*)s) ;
  }

  b2Contact * ourContact( b2Contact * c );
  b2Manifold * ourManifold( b2Manifold * c );
  b2ContactImpulse * ourContactImpulse( b2ContactImpulse * c );


  virtual void BeginContact(b2Contact* contact)
  { 
    if (beginContact) {
      /* fprintf(stderr,"BeginContact:Going to call our SV!\n"); */

      //ST(0) = sv_newmortal();
      //sv_setref_pv( ST(0), CLASS, (void*)RETVAL );


      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);		
      // make a b2Contact and put it there!
      const char* CLASS = "Box2D::b2Contact";
      SV * contactSV = sv_newmortal();
      sv_setref_pv( contactSV, CLASS, (void*)contact );
      XPUSHs( contactSV ); //sv_2mortal( newSVpv( "Begin",0 )));
      PUTBACK;
      call_sv( (SV*)beginContact, G_DISCARD );
      FREETMPS;
      LEAVE;
    } else {
      /* fprintf(stderr,"BeginContact: Didn't call our SV!\n"); */
    }
  }
  
  virtual void EndContact(b2Contact* contact)
  { 
    if (endContact) {
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      const char* CLASS = "Box2D::b2Contact";
      SV * contactSV = sv_newmortal();
      sv_setref_pv( contactSV, CLASS, (void*)contact );
      XPUSHs( contactSV ); //sv_2mortal( newSVpv( "Begin",0 )));
      //XPUSHs( sv_2mortal( newSVpv( "End",0)));//ourContact(contact), 0 )));
      PUTBACK;
      call_sv( (SV*)endContact, G_DISCARD );
      FREETMPS;
      LEAVE;
    }
  }
  
  virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
  { 
    if (preSolve) {
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);

      const char* CLASS1 = "Box2D::b2Contact";
      SV * contactSV = sv_newmortal();
      sv_setref_pv( contactSV, CLASS1, (void*)contact );
      XPUSHs( contactSV ); //sv_2mortal( newSVpv( "Begin",0 )));

      const char* CLASS2 = "Box2D::b2Manifold";
      SV * manifoldSV = sv_newmortal();
      sv_setref_pv( manifoldSV, CLASS2, (void*) oldManifold );
      XPUSHs( manifoldSV ); //sv_2mortal( newSVpv( "Begin",0 )));

      XPUSHs( sv_2mortal( newSVpv( "preC",0)));//ourContact(contact), 0 )));
      XPUSHs( sv_2mortal( newSVpv( "preM",0)));//ourManifold(oldManifold), 0 )));
      PUTBACK;
      call_sv( (SV*)preSolve, G_DISCARD );
      FREETMPS;
      LEAVE;
      
    }
  }


  virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) 
  {
    if (postSolve) {
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      //XPUSHs( sv_2mortal( newSVpv( "postC",0)));//ourContact(contact), 0 )));
      //XPUSHs( sv_2mortal( newSVsv(ourContact(contact))));
      //XPUSHs( sv_2mortal( newSVpv( "postM",0)));//ourManifold(oldManifold), 0 )));
      //XPUSHs( sv_2mortal( newSVsv(oldManifold)));

      const char* CLASS1 = "Box2D::b2Contact";
      SV * contactSV = sv_newmortal();
      sv_setref_pv( contactSV, CLASS1, (void*)contact );
      XPUSHs( contactSV ); //sv_2mortal( newSVpv( "Begin",0 )));

      const char* CLASS2 = "Box2D::b2ContactImpulse";
      SV * impulseSV = sv_newmortal();
      sv_setref_pv( impulseSV, CLASS2, (void*) impulse );
      XPUSHs( impulseSV ); //sv_2mortal( newSVpv( "Begin",0 )));


      PUTBACK;
      call_sv( (SV*)postSolve, G_DISCARD );
      FREETMPS;
      LEAVE;
      
    } else {
      //fprintf(stderr,"PostSolve: Didn't call our SV!\n"); 
    }

  }

};

// void
// PerlContactListener::setEndContactSub(name)
//     SV *    name
//     CODE:
//         THIS->setEndContactSub( name );
// 
//         if (THIS->endContact == (SV*)NULL)
//             /* First time, so create a new SV */
//             THIS->endContact = (void*)newSVsv(name);
//         else
//             /* Been here before, so overwrite */
//             SvSetSV((SV*)(THIS->endContact), name);
// 
// 
// void
// PerlContactListener::setPreSolveSub(name)
//     SV *    name
//     CODE:
//         if (THIS->preSolve == (SV*)NULL)
//             /* First time, so create a new SV */
//             THIS->preSolve = (void*)newSVsv(name);
//         else
//             /* Been here before, so overwrite */
//             SvSetSV((SV*)(THIS->preSolve), name);
// 
// void
// PerlContactListener::setPostSolveSub(name)
//     SV *    name
//     CODE:
//         if (THIS->postSolve == (SV*)NULL)
//             /* First time, so create a new SV */
//             THIS->postSolve = (void*)newSVsv(name);
//         else
//             /* Been here before, so overwrite */
//             SvSetSV((SV*)(THIS->postSolve), name);
// 
// 


#endif
