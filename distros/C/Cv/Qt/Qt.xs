/* -*- mode: text; coding: utf-8; tab-width: 4 -*- */

#include "Cv.inc"

static void cb_button(int state, VOID* userdata)
{
	callback_t *p = (callback_t*)userdata;
	if (p && p->callback) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(state)));
		PUSHs(p->u.b.userdata? p->u.b.userdata : &PL_sv_undef);
		PUTBACK;
		// call_sv(p->callback, G_EVAL|G_DISCARD);
		call_sv(p->callback, G_DISCARD);
		FREETMPS;
		LEAVE;
	}
}

MODULE = Cv::Qt		PACKAGE = Cv::Qt

# ============================================================
#  highgui. High-level GUI and Media I/O: Qt new functions
# ============================================================

#if _CV_VERSION() >= _VERSION(2,0,0)

void
cvSetWindowProperty(const char* name, int prop_id, double prop_value)

double
cvGetWindowProperty(const char* name, int prop_id)

#endif

#if _CV_VERSION() >= _VERSION(2,2,0)

CvFont*
cvFontQt(const char* nameFont, int pointSize = -1, CvScalar color = cvScalarAll(0), int weight = CV_FONT_NORMAL, int style = CV_STYLE_NORMAL, int spacing = 0)
CODE:
	Newx(RETVAL, 1, CvFont);
	*RETVAL = cvFontQt(nameFont, pointSize, color, weight, style, spacing);
OUTPUT:
	RETVAL

void
cvAddText(const CvArr* img, const char* text, CvPoint location, CvFont *font)

void
cvDisplayOverlay(const char* name, const char* text, int delay)

void
cvDisplayStatusBar(const char* name, const char* text, int delayms)

#TBD# void cvCreateOpenGLCallback(const char* window_name, CvOpenGLCallback callbackOpenGL, VOID* userdata = NULL, double angle = -1, double zmin = -1, double zmax = -1)

void
cvSaveWindowParameters(const char* name)

void
cvLoadWindowParameters(const char* name)

#C# int cvCreateButton(const char* buttonName=NULL, CvButtonCallback onChange=NULL, VOID* userdata=NULL, int buttonType=CV_PUSH_BUTTON, int initialButtonState=0)

int
cvCreateButton(const char* buttonName=NULL, SV* onChange=NO_INIT, SV* userdata=NO_INIT, int buttonType=CV_PUSH_BUTTON, int initialButtonState=0)
PREINIT:
	callback_t* callback;
	AV* Cv_BUTTON;
	AV* av; SV* sv;
INIT:
	if (SvREF0(ST(0))) buttonName = NULL;
	if (items <= 1) onChange = (SV*)0;
	if (items <= 2) userdata = (SV*)0;
CODE:
	Newx(callback, 1, callback_t);
	callback->callback = 0;
	if (onChange && SvROK(onChange) && SvTYPE(SvRV(onChange)) == SVt_PVCV) {
		SvREFCNT_inc(callback->callback = (SV*)SvRV(onChange));
	}
	callback->u.b.userdata = 0;
	if (userdata) {
		SvREFCNT_inc(callback->u.b.userdata = userdata);
	}
	if (!(Cv_BUTTON = get_av("Cv::BUTTON", 0))) {
		Perl_croak(aTHX_ "Cv::cvCreateButton: can't get @Cv::BUTTON");
	} else {
		av_push(Cv_BUTTON, newSViv(PTR2IV(callback)));
	}
	RETVAL = cvCreateButton(
		buttonName, cb_button, callback, buttonType, initialButtonState);
OUTPUT:
	RETVAL

#endif
