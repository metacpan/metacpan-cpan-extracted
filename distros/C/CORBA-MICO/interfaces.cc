/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pmico.h"
#include <mico/ir.h>
#undef minor

const I32 OFFSET = 0x10000000;
const I32 OPERATION_BASE = 0;
const I32 GETTER_BASE = OPERATION_BASE + OFFSET;
const I32 SETTER_BASE = GETTER_BASE + OFFSET;

static char *repoid_key = "_repoid";
static CORBA::Repository *iface_repository = NULL;

PMicoIfaceInfo *
pmico_find_interface_description (const char *repoid) 
{
    HV *hv = get_hv("CORBA::MICO::_interfaces", TRUE);
    SV **result = hv_fetch (hv, (char *)repoid, strlen(repoid), 0);
    
    if (!result)
        return NULL;
    else
        return (PMicoIfaceInfo *)SvIV(*result);
}

static PMicoIfaceInfo *
store_interface_description (CORBA::InterfaceDef *iface)
{
    assert (iface != NULL);

    CORBA::InterfaceDef::FullInterfaceDescription *desc = 
      iface->describe_interface();

    const char *repoid = desc->id;
    U32 len = strlen(repoid);

    HV *hv = get_hv("CORBA::MICO::_interfaces", TRUE);
    SV **result = hv_fetch (hv, (char *)repoid, len, 0);

    if (result) {
        delete (PMicoIfaceInfo *)SvIV(*result);
    }

    {
        CORBA::String_var pkg = iface->absolute_name();
        const char *pkgname;
        if (!strncmp(pkg, "::", 2))     //FIXME:: always starts from '::' ?
            pkgname = pkg + 2;
        else
            pkgname = pkg;
 
        PMicoIfaceInfo *info = new PMicoIfaceInfo (pkgname, 
                                                   CORBA::InterfaceDef::_duplicate(iface),
                                                   desc);
        hv_store (hv, (char *)repoid, len, newSViv((IV)info), 0);
        
        SV *pkg_sv = get_sv ( (char *)(std::string (pkg) + "::" + repoid_key).c_str(), TRUE );
        sv_setpv (pkg_sv, repoid);
        return info;
    }
    
    return NULL;
}

static SV*
decode_exception (CORBA::Exception *ex,
                  CORBA::OperationDescription *opr)
{
    CORBA::UnknownUserException *uuex = CORBA::UnknownUserException::_downcast(ex);
    CM_DEBUG(("decode_exception(ex='%s')\n",ex->_repoid()));

    SV* exception_SV;
    if( uuex ) {
      // A user exception, check against the possible exceptions for this call.
      CM_DEBUG(("decode_exception():_except_repoid='%s')\n",uuex->_except_repoid()));
      if( opr ) {
          unsigned int i;
          for( i = 0; i < opr->exceptions.length(); i++ )
            if( !strcmp(opr->exceptions[i].id, uuex->_except_repoid()) ) {
              exception_SV = pmico_from_any( &uuex->exception( opr->exceptions[i].type ));
              break;
            }
          if( i == opr->exceptions.length() )
            exception_SV = pmico_system_except ( "IDL:omg.org/CORBA/UNKNOWN:1.0", 0, CORBA::COMPLETED_MAYBE );
      } else {
        exception_SV = pmico_system_except ( "IDL:omg.org/CORBA/UNKNOWN:1.0", 0, CORBA::COMPLETED_MAYBE );
      }
    } else {
      CORBA::SystemException *sysex = CORBA::SystemException::_downcast(ex);
      if( sysex ) {
        exception_SV = pmico_system_except ( sysex->_repoid(), sysex->minor(), sysex->completed() );
      } else {
        croak("Panic: caught an impossible exception");
      }
    }
    return exception_SV;
}

XS(_pmico_callStub)
{
    dXSARGS;

    SV **repoidp;
    char *repoid;
    std::string name;
    CORBA::ULong i,j;

    I32 index = XSANY.any_i32;
    
    repoidp = hv_fetch(CvSTASH(cv), repoid_key, strlen(repoid_key), 0);
    if (!repoidp)
        croak("_pmico_callStub called with bad package (no %s)",repoid_key);
    
    repoid = SvPV(GvSV(*repoidp), PL_na);
    
    PMicoIfaceInfo *info = pmico_find_interface_description (repoid);

    if (!info)
        croak("_pmico_callStub called on undefined interface");

    CORBA::InterfaceDef::FullInterfaceDescription *desc = info->desc;
  
    if (index >= OPERATION_BASE && index < GETTER_BASE) {
        name = std::string ( desc->operations[index-OPERATION_BASE].name );
    } else if (index >= GETTER_BASE && index < SETTER_BASE) {
        name = "_get_" + std::string ( desc->attributes[index-GETTER_BASE].name );
    } else if (index >= SETTER_BASE) {
        name = "_set_" + std::string ( desc->attributes[index-SETTER_BASE].name );
    }

    CM_DEBUG(("_pmico_callStub('%s','%s')\n",repoid,name.c_str()));

    // Get the discriminator 

    CORBA::Object_ptr obj;
    if (items < 1)
        croak("%s::%s must have object as first argument",
              HvNAME(CvSTASH(cv)), name.c_str ());

    obj = pmico_sv_to_objref(ST(0)); // may croak
    if( CORBA::is_nil (obj) )
      croak("%s::%s is nil object",
            HvNAME(CvSTASH(cv)), name.c_str ());


    // Form the request

    CORBA::Request_var req = obj->_request ( name.c_str() );

    if (index >= OPERATION_BASE && index < GETTER_BASE) {
        CORBA::OperationDescription *opr = &desc->operations[index-OPERATION_BASE];
        j = 1;
        for (i = 0 ; i<opr->parameters.length() ; i++) {
            SV *arg = (j<(CORBA::ULong)items) ? ST(j) : &PL_sv_undef;

            switch (opr->parameters[i].mode) {
            case CORBA::PARAM_IN:
                {
                  CORBA::Any_var argany = new CORBA::Any(opr->parameters[i].type, 0 );
                  if (!pmico_to_any ( argany , arg ))
                    croak ("Error marshalling parameter '%s'",
                           (char *)opr->parameters[i].name);
                  req->add_in_arg ( opr->parameters[i].name ) = *argany;
                }
                j++;
                break;
            case CORBA::PARAM_INOUT:
                if (!SvROK(arg))
                    croak ("INOUT parameter must be a reference");
                {
                  CORBA::Any_var argany = new CORBA::Any(opr->parameters[i].type, 0 );
                  if (!pmico_to_any ( argany , SvRV(arg) ))
                      croak ("Error marshalling parameter '%s'",
                             (char *)opr->parameters[i].name);
                  req->add_inout_arg ( opr->parameters[i].name ) = *argany;
                }
                j++;
                break;
            case CORBA::PARAM_OUT:
                req->add_out_arg().set_type( opr->parameters[i].type );
                break;
            }
        }
        req->result()->value()->set_type ( opr->result );

        for( i = 0; i < opr->exceptions.length(); i++ ) {
          req->exceptions()->add( opr->exceptions[i].type );
        }
    } else if (index >= GETTER_BASE && index < SETTER_BASE) {
        req->result()->value()->set_type ( desc->attributes[index-GETTER_BASE].type );

    } else if (index >= SETTER_BASE) {
        if (items < 2)
          croak("%s::%s called without second argument",
                HvNAME(CvSTASH(cv)), name.c_str ());

        CORBA::Any_var argany = new CORBA::Any(desc->attributes[index-SETTER_BASE].type, 0 );
        if (!pmico_to_any (argany, ST(1)))
            croak ("Error marshalling attribute value");
        req->add_in_arg ( "_value" ) = *argany;

        req->result()->value()->type ( CORBA::_tc_void );
    }

    // Invoke request

    try {
      req->invoke();
    } catch(CORBA::Exception) {
    }

    CORBA::Exception* excp = req->env()->exception();
    SV* exception_SV;
    if (excp) {
        CM_DEBUG(("_pmico_callStub():excp->_repoid='%s'\n",excp->_repoid()));
        CORBA::OperationDescription *opr;
        if (index >= OPERATION_BASE && index < GETTER_BASE) {
            opr = &desc->operations[index-OPERATION_BASE];
        } else {
            opr = NULL;
        }
        exception_SV = decode_exception( excp, opr );
    } else {
      exception_SV = newSVsv(&PL_sv_undef);
    }

    // Get return and inout, and inout parameters

    I32 return_count = 0;
    
    if (req->result()->value()->type()->kind() != CORBA::tk_void) {
        // FIXME, do the right thing in array and scalar contexts
        SV *res = pmico_from_any (req->result()->value());
        if (res)
          ST(0) = sv_2mortal(res);      // we have at least 1 argument
        else
          ST(0) = &PL_sv_undef;
        return_count++;
    }

    // Is this safe? If we end up calling back to perl, could the
    // stack already be overridden?

    j = 1;
    for (i = 0; i < req->arguments()->count() ; i++) {
        CORBA::NamedValue *item = req->arguments()->item(i);
        if (item->flags() & CORBA::ARG_INOUT) {
            SV *res = pmico_from_any (item->value());
            if (res)
              sv_setsv (SvRV(ST(j)), res);
            else
              sv_setsv (SvRV(ST(j)), &PL_sv_undef);
            j++;
        } else if (item->flags () & CORBA::ARG_IN) {
            j++;
        }
    }

    for (i = 0; i < req->arguments()->count() ; i++) {
        CORBA::NamedValue *item = req->arguments()->item(i);
        if (item->flags() & CORBA::ARG_OUT) {
            SV *res = pmico_from_any (item->value());
            if (return_count >= items)
                EXTEND(sp,1);
            if (res)
              ST(return_count) = sv_2mortal (res);
            else
              ST(return_count) = &PL_sv_undef;
            return_count++;
        }
    }

    // Put exception object as last result value
    {
      EXTEND(SP,1);
      ST(return_count) = sv_2mortal( exception_SV );
      return_count++;
    }

    XSRETURN(return_count);
}

XS(_pmico_repoid) {
    dXSARGS;

    ST(0) = (SV *)CvXSUBANY(cv).any_ptr;

    XSRETURN(1);
}

static void
define_exception (const char *repoid)
{
    CM_DEBUG(("define_exception('%s')\n",repoid));
    if (pmico_find_exception(repoid))
        return;

    CORBA::String_var pack = 
        iface_repository->lookup_id ((char *)repoid)->absolute_name();

    char *pkg = pack;
    if (!strncmp(pkg, "::", 2))
        pkg += 2;

    pmico_setup_exception (repoid, pkg, "CORBA::UserException");
}

static void
define_method (const char *pkg, const char *prefix, const char *name, I32 index)
{
    std::string fullname = std::string (pkg) + prefix + name;
    if( get_cv( (char *)fullname.c_str(), 0 ) ) {
      return;
    }

    CV *method_cv = newXS ((char *)(fullname + "_pmico_callStub").c_str(),
                           _pmico_callStub, __FILE__);
    // use Perl any_i32 var as store for method index
    CvXSUBANY(method_cv).any_i32 = index;
    // set STASH for method CV (otherwise it is NULL)
    CvSTASH (method_cv) = gv_stashpv ((char *)pkg, 0);

    eval_pv( (
      std::string("sub ") + fullname + "{"+
      "my @r=" + fullname + "_pmico_callStub(@_);"+
      "my $e=pop @r;"+
      "Error::throw($e) if defined $e;"+
      "return (@r==1)?$r[0]:@r;"+
      "}").c_str(), TRUE );
}

static void
ensure_iface_repository (CORBA::ORB_ptr _orb)
{
    if (iface_repository == NULL) {
        CORBA::ORB_var orb = CORBA::ORB::_duplicate(_orb);
        if (CORBA::is_nil(orb))
            orb = CORBA::ORB_instance ("mico-local-orb", TRUE);
        
        CORBA::Object_var obj = 
            orb->resolve_initial_references("InterfaceRepository");
        iface_repository = CORBA::Repository::_narrow(obj);
    }
    
    if (iface_repository == NULL)
        croak("Cannot contact interface repository");
}

static PMicoIfaceInfo *
pmico_init_interface (CORBA::InterfaceDef *iface, const char *id)
{
    // Save the interface description for later reference
    PMicoIfaceInfo *info = store_interface_description (iface);

    CORBA::InterfaceDef::FullInterfaceDescription *desc = info->desc;

    if (!id)
        id = desc->id;

    // Set up the interface's operations and attributes
    unsigned int i;
    for ( i = 0 ; i < desc->operations.length() ; i++) {
        CORBA::OperationDescription *opr = &desc->operations[i];
        define_method (info->pkg.c_str(), "::", opr->name, OPERATION_BASE + i);
        for ( unsigned int j = 0 ; j < opr->exceptions.length() ; j++)
          define_exception ( opr->exceptions[j].id );
    }

    for ( i = 0 ; i < desc->attributes.length() ; i++) {
        if (desc->attributes[i].mode == CORBA::ATTR_NORMAL) {
            define_method (info->pkg.c_str(), "::_set_", desc->attributes[i].name, 
                           SETTER_BASE + i);
        }
        define_method (info->pkg.c_str(), "::_get_", desc->attributes[i].name, 
                       GETTER_BASE + i);
    }

    // Register the base interfaces
    
    AV *isa_av = get_av ( (char *)(info->pkg + "::ISA").c_str(), TRUE );

    for ( i = 0 ; i < desc->base_interfaces.length() ; i++) {
        PMicoIfaceInfo *info = pmico_find_interface_description(desc->base_interfaces[i]);
        if (!info) {
                CORBA::Contained_var base = iface_repository->lookup_id (desc->base_interfaces[i]);
                if (!CORBA::is_nil (base) && 
                    (base->def_kind() == CORBA::dk_Interface)) {
                    CORBA::InterfaceDef_var intf = CORBA::InterfaceDef::_narrow (base);
                    info = pmico_load_contained (intf, NULL, NULL);
                }
        }
        if (info)
            av_push (isa_av, newSVpv((char *)info->pkg.c_str(), 0));
    }

    if (desc->base_interfaces.length() == 0) {
        av_push (isa_av, newSVpv("CORBA::Object", 0));
    }

    // Set up the server side package

    isa_av = get_av ( (char *)("POA_" + info->pkg + "::ISA").c_str(), TRUE );
    av_push (isa_av, newSVpv("PortableServer::ServantBase", 0));

    // Create a package method that will allow us to determine the
    // repository id before we have the MICO object set up

    std::string fullname = "POA_" + info->pkg + "::_pmico_repoid";
    CV *method_cv = newXS ((char *)fullname.c_str(), _pmico_repoid, __FILE__);
    CvXSUBANY(method_cv).any_ptr = (void *)newSVpv((char *)id, 0);

    return info;
}

void
pmico_init_constant (const char *pkgname, CORBA::ConstantDef_ptr cd)
{
    CORBA::String_var name = cd->name();

    // Extract the value

    CORBA::Any_var value = cd->value();
    SV *sv = pmico_from_any (value);

    // Create a constant-valued sub with that value
    
    HV *stash = gv_stashpv ((char *)pkgname, TRUE);
    newCONSTSUB (stash, name, sv);
}

PMicoIfaceInfo *
pmico_load_contained (CORBA::Contained *_contained, CORBA::ORB_ptr _orb,
                      const char *_id)
{
    assert (_contained != NULL || _id != NULL);
    CM_DEBUG(("pmico_load_contained(%p,%p,'%s')\n",_contained,_orb,_id));

    CORBA::Contained_var contained = CORBA::Contained::_duplicate (_contained);
    
    if (!contained) {
        ensure_iface_repository (_orb);

        contained = iface_repository->lookup_id((char *)_id);
        if (CORBA::is_nil(contained))
            croak("Cannot find '%s' in interface repository", _id);
    }

    if (!iface_repository)
        iface_repository = contained->containing_repository();

    // If the container is an interface, suck all the information
    // out of it for later use.

    PMicoIfaceInfo *retval;
    CORBA::InterfaceDef_var iface = CORBA::InterfaceDef::_narrow (contained);
    if (iface)
        retval = pmico_init_interface (iface, _id);
    else
        retval =  NULL;

    // If the container is an exception, define it
    CORBA::ExceptionDef_var excp = CORBA::ExceptionDef::_narrow (contained);
    if( excp )
        define_exception( excp->id() );

    // if contained is Constant then init it
    CORBA::ConstantDef_var cnst = CORBA::ConstantDef::_narrow( contained );
    if( cnst ) {
        std::string pkgname;

        CORBA::String_var pkg = contained->absolute_name();
        pkgname = pkg;
        unsigned int colon = pkgname.rfind( "::" );
        if( colon == std::string::npos )
            pkgname = "";
        else
            pkgname = pkgname.substr( 0, colon );

        pmico_init_constant( pkgname.c_str(), cnst );
    }

    // Initialize all constants in the container, and all
    // enclosed interfaces.
    
    CORBA::Container_var container = CORBA::Container::_narrow (contained);
    if (container) {

        CORBA::ContainedSeq_var contents = 
            container->contents (CORBA::dk_Constant, true);

        if (contents->length() > 0) {
          std::string pkgname;

            if (retval)
                pkgname = retval->pkg.c_str();
            else {
                CORBA::String_var pkg = contained->absolute_name();
                if (!strncmp(pkg, "::", 2))
                    pkgname = &pkg[(CORBA::ULong)2];
                else
                    pkgname = pkg;
            }

            for (CORBA::ULong i = 0; i<contents->length(); i++) {
                CORBA::ConstantDef_var cd =
                    CORBA::ConstantDef::_narrow (contents[i]);
                pmico_init_constant (pkgname.c_str(), cd);
            }
        }

        contents = container->contents (CORBA::dk_Interface, true);

        for (CORBA::ULong i = 0; i<contents->length(); i++) {
            if (!pmico_find_interface_description (contents[i]->id()))
                pmico_load_contained (contents[i], _orb, NULL);
        }
    }

    return retval;
}

static HV *typecode_cache;

SV *
store_typecode (const char *id, CORBA::TypeCode_ptr tc)
{
    if (!typecode_cache)
        typecode_cache = newHV();

    SV *res = newSV(0);

    sv_setref_pv (res, "CORBA::TypeCode", (void *)tc);
    hv_store (typecode_cache, (char *)id, strlen(id), res, 0);
    
    return res;
}

SV *
pmico_lookup_typecode (const char *id)
{
    if (!typecode_cache)
        typecode_cache = newHV();

    SV **svp = hv_fetch (typecode_cache, (char *)id, strlen(id), 0);

    if (!svp) {
        ensure_iface_repository (NULL);

        CORBA::Contained_var c = iface_repository->lookup_id ((char *)id);
        CORBA::IDLType_var t = CORBA::IDLType::_narrow(c);
        
        if (CORBA::is_nil(t))
            return NULL;

        CORBA::TypeCode_ptr tc = t->type();

        return SvREFCNT_inc(store_typecode (id, tc));
    }

    return SvREFCNT_inc(*svp);
}

void
pmico_init_typecodes (void)
{
    store_typecode ("IDL:CORBA/Short:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_short));
    store_typecode ("IDL:CORBA/Long:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_long));
    store_typecode ("IDL:CORBA/UShort:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_ushort));
    store_typecode ("IDL:CORBA/ULong:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_ulong));
    store_typecode ("IDL:CORBA/Float:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_float));
    store_typecode ("IDL:CORBA/Double:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_double));
    store_typecode ("IDL:CORBA/Boolean:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_boolean));
    store_typecode ("IDL:CORBA/Char:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_char));
    store_typecode ("IDL:CORBA/Octet:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_octet));
    store_typecode ("IDL:CORBA/Any:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_any));
    store_typecode ("IDL:CORBA/TypeCode:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_TypeCode));
    store_typecode ("IDL:CORBA/Principal:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_Principal));
    store_typecode ("IDL:CORBA/Object:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_Object));
    store_typecode ("IDL:CORBA/String:1.0", 
                    CORBA::TypeCode::_duplicate(CORBA::_tc_string));
}
