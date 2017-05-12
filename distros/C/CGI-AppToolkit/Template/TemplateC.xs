#include "Template/TemplateC.h"

extern "C" {
#include "XSUB.h"
}

MODULE = CGI::AppToolkit::Template::TemplateC  PACKAGE = CGI::AppToolkit::Template::TemplateC
PROTOTYPES: ENABLE

TemplateC *
TemplateC::new(text)
	char* text
	
void
TemplateC::DESTROY()

SV*
TemplateC::value(callback, value)
	SV* callback
	SV* value

bool
TemplateC::has_error()

SV*
TemplateC::get_error()

SV*
TemplateC::get_vars()

# MODULE = TemplateC  PACKAGE = TemplateC::TextNode
# PROTOTYPES: ENABLE
# 
# void
# TextNode::DESTROY()
# 
# 
# MODULE = TemplateC  PACKAGE = TemplateC::TokenNode
# PROTOTYPES: ENABLE
# 
# void
# TokenNode::DESTROY()
# 
# 
# MODULE = TemplateC  PACKAGE = TemplateC::DecisionNode
# PROTOTYPES: ENABLE
# 
# void
# DecisionNode::DESTROY()
# 
# 
# MODULE = TemplateC  PACKAGE = TemplateC::RepeatNode
# PROTOTYPES: ENABLE
# 
# void
# RepeatNode::DESTROY()
