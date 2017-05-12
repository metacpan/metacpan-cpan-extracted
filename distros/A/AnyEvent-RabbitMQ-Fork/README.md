The goal of this module id narrow and very specific: manage an AMQP connection
away from potential sources of TCP socket blocking. If your application use of
AnyEvent::RabbitMQ is light, does not handle high message volume, or never does
other work which might block the TCP socket, then this is likely not for you.

I, however, at $work have run into these scenarios. Through difficulty and/or
laziness, I have found it difficult to keep my AMQP connection happy. So I
embarked on creating this library to ease some pain. Hopefully it can ease yours
as well.
