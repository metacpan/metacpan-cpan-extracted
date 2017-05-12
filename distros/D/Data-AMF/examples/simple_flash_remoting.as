package {
    import flash.display.*;
    import flash.net.*;
    import flash.events.*;

    public class simple_flash_remoting extends Sprite {
        private var nc:NetConnection;

        public function simple_flash_remoting() {
            nc = new NetConnection();
            nc.objectEncoding = ObjectEncoding.AMF0;
            nc.addEventListener( AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler );
            nc.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
            nc.addEventListener( NetStatusEvent.NET_STATUS, netStatusHandler );
            nc.addEventListener( SecurityErrorEvent.SECURITY_ERROR, securityErrorEvent );

            nc.connect("http://localhost:3000/gateway");
            nc.call("echo", new Responder(echo_result, remote_error), "foo", "bar");
            nc.call("sum", new Responder(sum_result, remote_error), 1, 1);
        }

        private function echo_result(...args):void {
            log('echo_result');
            log(args);
        }

        private function sum_result(...args):void {
            log('sum_result');
            log(args);
        }

        private function remote_error(...args):void {
            log('remote_error');
            log(args);
        }

        private function asyncErrorHandler(e:AsyncErrorEvent):void {}
        private function ioErrorHandler(e:IOErrorEvent):void {}
        private function netStatusHandler(e:NetStatusEvent):void {}
        private function securityErrorEvent(e:SecurityErrorEvent):void {}
    }
}
