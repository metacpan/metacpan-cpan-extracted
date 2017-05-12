/* -*- mode: C++; c-file-style: "bsd" -*- */

#ifndef __DISPATCHER_H__
#define __DISPATCHER_H__

class PMicoDispatcherCallback : public CORBA::DispatcherCallback {
  SV *_callback;
  AV *_args;
  
 public:
  PMicoDispatcherCallback (SV *callback, AV *args)
    : _callback (callback), _args (args) {}
  ~PMicoDispatcherCallback ();
  
  void callback (CORBA::Dispatcher *dispatcher, CORBA::Dispatcher::Event);
};
#endif /* __DISPATCHER_H__ */

